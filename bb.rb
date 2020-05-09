#!/usr/bin/env ruby

require_relative 'opcode'

# Conditional jump
INST_CJMP = ['jbe', 'jle', 'jeq', 'jne', 'jbt', 'jlt']
# Unconditional jump
INST_UJMP = ['jmp_offset']
# Jump to (not call) another procedure/label
INST_PROCJUMP = ['goto', 'option']
INST_RET = ['return', 'exit', 'eof']

class RIOBasicBlock
    def initialize(entry)
        # Type of bb
        @type = 'linear'
        # Begin address of bb (inclusive)
        @entry = entry
        # End address of bb (exclusive)
        @exit = nil
        # Address of the next bb (default or true cjmp)
        @jump_true = nil
        # Address of the next bb (if cjmp evaluates to false)
        @jump_false = nil
        # Quick look-back table for doing reverse lookups. Points to the beginning of predecessor bb
        @jumped_from = []
        @exit_procs = []
    end

    def to_s()
        jump_true_s = (@jump_true.nil?) ? 'nil' : "0x#{@jump_true.to_s(16)}"
        jump_false_s = (@jump_false.nil?) ? 'nil' : "0x#{@jump_false.to_s(16)}"
        entry_s = (@entry.nil?) ? 'nil' : "0x#{@entry.to_s(16)}"
        exit_s = (@exit.nil?) ? 'nil' : "0x#{@exit.to_s(16)}"
        return "RIOBasicBlock(type=#{@type.inspect}, entry=#{entry_s}, exit=#{exit_s}, jump_true=#{jump_true_s}, jump_false=#{jump_false_s}, exit_procs=#{@exit_procs.inspect})"
    end

    def split!(offset)
        other = RIOBasicBlock.new(offset)
        other.exit = @exit
        other.type = @type
        other.jump_true = @jump_true
        other.jump_false = @jump_false
        other.jumped_from << @entry
        other.exit_procs = @exit_procs.dup()
        @type = 'linear'
        @exit = offset
        @jump_true = offset
        @jump_false = nil
        @exit_procs.clear()
        return other
    end

    def within?(offset)
        return (@entry..@exit-1) === offset
    end

    def length()
        return @exit - @entry rescue 0
    end
    attr_accessor :type, :entry, :exit, :jump_true, :jump_false, :exit_procs, :jumped_from
end

class RIOControlFlow
    def initialize(disasm)
        @disasm = disasm
        # Procedures that this procedure jump to
        @exits = []
        @bb = []
        @bb_by_entry = {}
        @_current_bb = nil
        process_disasm()
    end

    def inside_bb(offset)
        @bb.each do |bb|
            if bb.exit.nil?
                next
            elsif bb.within?(offset)
                return bb
            end
        end
        return nil
    end

    def get_bb_by_offset(offset)
        return @bb_by_entry[offset]
    end

    def define_bb_at(offset, jumped_from)
        # Check if bb is already defined
        if @bb_by_entry[offset].nil?
            # Not already defined.
            #puts "New bb @ 0x#{offset.to_s(16)}"
            new_bb = nil
            # Split an existing bb if the current offset is within it
            split_bb = inside_bb(offset)
            new_bb = split_bb.split!(offset) unless split_bb.nil?
            # Create a new bb if the above yields no result
            new_bb = RIOBasicBlock.new(offset) if new_bb.nil?
            new_bb.jumped_from << jumped_from
            # Save the new bb
            @bb_by_entry[offset] = new_bb
            @bb << new_bb
        else
            # Already defined. Return the already defined bb.
            new_bb = @bb_by_entry[offset]
        end
        return new_bb
    end

    def _decode_options(args)
        result = []
        (args.length / 6).times do |i|
            opt = args[(i * 6)..((i + 1) * 6)]
            result << opt[5].upcase()
        end
        return result
    end

    def process_disasm()
        # Initialize entry
        current_bb = RIOBasicBlock.new(0)
        @bb << current_bb
        @bb_by_entry[0] = current_bb

        @disasm.each_with_index do |inst, index|
            # Current inst matches a bb start
            unless @bb_by_entry[inst[0]].nil?
                # Termination of a linear bb: hit some other bbs
                unless current_bb.entry == @bb_by_entry[inst[0]].entry
                    current_bb.exit = inst[0]
                    # TODO is there better way to blacklist terminal bbs?
                    current_bb.jump_true = inst[0] unless current_bb.type == 'procjump'
                end
                # Switch current bb to the matched one
                current_bb = @bb_by_entry[inst[0]]
            end
            offset = inst[0]
            op = inst[1]
            args = inst[2..-1]
            # Check for non-linear bb termination
            # CJMP
            if INST_CJMP.include?(op)
                #puts "cjmp @ 0x#{inst[0].to_s(16)}"
                current_bb.type = 'cjmp'
                # Exits at next inst
                current_bb.exit = @disasm[index+1][0]
                # F -> next inst + jump distance, T -> next inst
                current_bb.jump_false = @disasm[index+1][0] + args[2]
                current_bb.jump_true = @disasm[index+1][0]

                # Create 2 new bbs that start at the addresses mentioned above if they don't exist
                define_bb_at(current_bb.jump_true, current_bb.entry)
                define_bb_at(current_bb.jump_false, current_bb.entry)
            # UJMP
            elsif INST_UJMP.include?(op)
                #puts "ujmp @ 0x#{inst[0].to_s(16)}"
                current_bb.type = 'ujmp'
                current_bb.exit = @disasm[index+1][0]
                current_bb.jump_true = args[0]
                define_bb_at(current_bb.jump_true, current_bb.entry)
                define_bb_at(current_bb.exit, current_bb.entry)
            # procjump (terminates the execution)
            elsif INST_PROCJUMP.include?(op)
                #puts "procjump @ 0x#{inst[0].to_s(16)}"
                current_bb.type = 'procjump'
                current_bb.exit = @disasm[index+1][0]
                case op
                when 'option'
                    current_bb.exit_procs.concat(_decode_options(args))
                when 'goto'
                    current_bb.exit_procs << args[0]
                end
                define_bb_at(current_bb.exit, current_bb.entry)
            # ret (terminates the execution)
            elsif INST_RET.include?(op)
                current_bb.type = 'ret'
                current_bb.exit = @disasm[index+1][0]
                define_bb_at(current_bb.exit, current_bb.entry)
            # disasm EOF (not script 'eof' mark)
            elsif op == 'EOF'
                current_bb.exit = inst[0]
            end
        end
        @bb_by_entry.clear()
        @bb.reject! { |block| block.length == 0 }
        @bb.each { |block| @bb_by_entry[block.entry] = block }
    end

    def to_gv()
        puts 'digraph RIOBasicBlockGraph {'
        @bb.each do |bb|
            bb_name = "RIO_#{bb.entry}"
            bb_disp = "0x#{bb.entry.to_s(16)}:0x#{bb.exit.to_s(16)}"
            case bb.type
            when 'linear', 'ujmp'
                puts "  #{bb_name} [shape=\"box\", label=\"#{bb_disp}\"];"
                puts "  #{bb_name} -> RIO_#{bb.jump_true} [color=\"blue\"];" unless bb.jump_true.nil?
            when 'cjmp'
                puts "  #{bb_name} [shape=\"diamond\" label=\"#{bb_disp}\"];"
                puts "  #{bb_name} -> RIO_#{bb.jump_true} [color=\"green\"];"
                puts "  #{bb_name} -> RIO_#{bb.jump_false} [color=\"red\"];"
            when 'procjump'
                shape = bb.exit_procs.length == 1 ? 'box' : 'diamond'
                puts "  #{bb_name} [shape=\"#{shape}\", color=\"blue\", label=\"#{bb_disp}\"];"
                bb.exit_procs.each do |p|
                    puts "  RIO_PROC_#{p} [shape=\"box\", style=\"rounded\", color=\"blue\", label=\"#{p}\"];"
                    puts "  #{bb_name} -> RIO_PROC_#{p} [color=\"blue\"]"
                end
            when 'ret'
                puts "  #{bb_name} [shape=\"box\", color=\"red\", label=\"#{bb_disp}\"];"
            end
        end
        puts '}'
    end
end
