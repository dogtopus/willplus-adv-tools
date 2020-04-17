#!/usr/bin/env ruby

require_relative 'opcode'

# Conditional jump
INST_CJMP = ['jbe', 'jle', 'jeq', 'jne', 'jbt', 'jlt']
# Unconditional jump
INST_UJMP = ['jmp_offset']
# Jump to (not call) another procedure/label
INST_PROCJUMP = ['goto', 'option']

class RIOBaseBlock
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
        @exit_procs = []
    end

    def to_s()
        jump_true_s = (@jump_true.nil?) ? 'nil' : "0x#{@jump_true.to_s(16)}"
        jump_false_s = (@jump_false.nil?) ? 'nil' : "0x#{@jump_false.to_s(16)}"
        return "RIOBaseBlock(type=#{@type.inspect}, entry=0x#{@entry.to_s(16)}, exit=0x#{@exit.to_s(16)}, jump_true=#{jump_true_s}, jump_false=#{jump_false_s}, exit_procs=#{@exit_procs.inspect})"
    end
    attr_accessor :type, :entry, :exit, :jump_true, :jump_false, :exit_procs
end

class RIOProcedure
    def initialize(disasm)
        @disasm = disasm
        # Procedures that this procedure jump to
        @exits = []
        @bb = []
        @bb_by_entry = {}
        @_current_bb = nil
        process_disasm()
    end

    def process_disasm()
        # Initialize entry
        current_bb = RIOBaseBlock.new(0)
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
                puts "cjmp @ #{inst[0].to_s}"
                current_bb.type = 'cjmp'
                # Exits at next inst
                current_bb.exit = @disasm[index+1][0]
                # F -> next inst + jump distance, T -> next inst
                current_bb.jump_false = @disasm[index+1][0] + args[2]
                current_bb.jump_true = @disasm[index+1][0]

                # Create 2 new bbs that start at the addresses mentioned above if they don't exist
                if @bb_by_entry[current_bb.jump_true].nil?
                    new_bb = RIOBaseBlock.new(current_bb.jump_true)
                    @bb_by_entry[current_bb.jump_true] = new_bb
                    @bb << new_bb
                end
                if @bb_by_entry[current_bb.jump_false].nil?
                    new_bb = RIOBaseBlock.new(current_bb.jump_false)
                    @bb_by_entry[current_bb.jump_false] = new_bb
                    @bb << new_bb
                end
            # UJMP
            elsif INST_UJMP.include?(op)
                puts "ujmp @ #{inst[0].to_s}"
                current_bb.type = 'ujmp'
                current_bb.exit = @disasm[index+1][0]
                current_bb.jump_true = @disasm[index+1][0] + args[0]
                if @bb_by_entry[current_bb.jump_true].nil?
                    new_bb = RIOBaseBlock.new(current_bb.jump_true)
                    @bb_by_entry[current_bb.jump_true] = new_bb
                    @bb << new_bb
                end
            # procjump (terminates the execution)
            elsif INST_PROCJUMP.include?(op)
                puts "procjump @ #{inst[0].to_s}"
                current_bb.type = 'procjump'
                current_bb.exit = @disasm[index+1][0]
                current_bb.exit_procs.concat()
                if @bb_by_entry[@disasm[index+1][0]].nil?
                    new_bb = RIOBaseBlock.new(@disasm[index+1][0])
                    @bb_by_entry[@disasm[index+1][0]] = new_bb
                    @bb << new_bb
                end
            # TODO exit?
            # disasm EOF (not script 'eof' mark)
            elsif op == 'EOF'
                current_bb.type = 'linear'
                current_bb.exit = inst[0]
            end
        end
        @bb.each do |bb|
            puts bb.to_s
        end
    end
end
