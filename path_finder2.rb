#!/usr/bin/env ruby
require_relative 'opcode'
require_relative 'bb'
require_relative 'op2rpy_settings'
require_relative 'op2rpy_settings_enum'

include O2RSettings
include O2RSettingsEnum

COND_TABLE = {
    'jeq' => '==',
    'jne' => '!=',
    'jbt' => '>',
    'jlt' => '<',
    'jbe' => '>=',
    'jle' => '<=',
}

SET_TABLE = {
    'mov' => '=',
    'add' => '+=',
    'sub' => '-=',
    'mul' => '*=',
    'div' => '/=',
}

def generate_set_expr(op, lflag, is_flag, rside)
    # TODO resolve flag name
    lref = FLAG_TABLE[lflag][0] rescue "[#{lflag}]"
    if is_flag != 0
        rref = FLAG_TABLE[rside][0] rescue "[#{rside}]"
        return "#{lref} = randint(0, #{rref})" if op == 'rnd'
        return "#{lref} #{SET_TABLE[op]} #{rref}"
    else
        return "#{lref} = randint(0, #{rside})" if op == 'rnd'
        return "#{lref} #{SET_TABLE[op]} #{rside}"
    end
end

def generate_cjmp_expr(op, lflag, rimm)
    lref = FLAG_TABLE[lflag][0] rescue "[#{lflag}]"
    return "#{lref} #{COND_TABLE[op]} #{rimm}"
end

def grouping_options(args)
    result = []
    (args.length / 6).times do |i|
        opt = args[(i * 6)..((i + 1) * 6)]
        opt[1].encode!('utf-8', RIO_TEXT_ENCODING)
        result << opt
    end
    return result
end

RIOOpCode.set_opcode_version(OPCODE_VERSION) unless OPCODE_VERSION.nil?
puts('digraph RIOFlowChart {')
puts('  graph [splines="ortho"];')
puts('  node [shape="box"];')
edges = []
ARGV.each do |fn|
    scrname = File.basename(fn).split('.')[0]
    # Cluster
    puts "  subgraph cluster_RIO_#{scrname} {"
    puts "    label = \"RIO_#{scrname}\";"
    scr = RIOOpCode.decode_script(IO.binread(fn), true)
    scr_lineno_by_offset = {}
    scr.each_with_index { |inst, lineno| scr_lineno_by_offset[inst[0]] = lineno }
    cfg = RIOControlFlow.new(scr)
    cfg.each_bb do |bb|
        entry_line = scr_lineno_by_offset[bb.entry]
        exit_line = scr_lineno_by_offset[bb.exit] - 1
        puts "    subgraph cluster_RIO_#{scrname}_0x#{bb.entry.to_s(16)}_0x#{bb.exit.to_s(16)} {"
        puts "      label = \"0x#{bb.entry.to_s(16)}-0x#{bb.exit.to_s(16)}\";"
        prev_node_offset = nil
        scr[entry_line..exit_line].each do |inst|
            offset = inst[0]
            op = inst[1]
            args = inst[2..-1]
            case op
            when 'mov', 'add', 'sub', 'mul', 'div', 'rnd'
                flag_prop = FLAG_TABLE[args[0]]
                if flag_prop.nil? || (!flag_prop.nil? && flag_prop[2] != FlagCategory::SYSTEM)
                    puts "      RIO_#{scrname}_0x#{offset.to_s(16)} [label=\"#{generate_set_expr(op, args[0], args[1], args[2])}\"];"
                    edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{scrname}_0x#{offset.to_s(16)} [color=\"blue\"];" unless prev_node_offset.nil?
                    prev_node_offset = offset
                end
            when 'jeq', 'jne', 'jbt', 'jlt', 'jbe', 'jle'
                puts "      RIO_#{scrname}_0x#{offset.to_s(16)} [shape=\"hexagon\", label=\"#{generate_cjmp_expr(op, args[0], args[1])}\"];"
                edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{scrname}_0x#{offset.to_s(16)} [color=\"blue\"];" unless prev_node_offset.nil?
                prev_node_offset = offset
            when 'option'
                options = grouping_options(args)
                # Define root node
                option_root_node = "RIO_#{scrname}_0x#{offset.to_s(16)}"
                puts "      #{option_root_node} [shape=\"hexagon\", label=\"option\", color=\"blue\"];"
                options.each_with_index do |opt, opt_index|
                    option_node = "RIO_#{scrname}_0x#{offset.to_s(16)}_opt#{opt_index}"
                    # Define option node
                    puts "      #{option_node} [label=\"#{opt[1]}\", color=\"blue\"];"
                    # Connect to option root node
                    edges << "#{option_root_node} -> #{option_node} [color=\"magenta\"];"
                    # Connect to procedure start node
                    edges << "#{option_node} -> RIO_#{opt[5].upcase()}_0x0 [color=\"cyan\"];"
                end
                # Connect to previous node
                edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> #{option_root_node} [color=\"blue\"];" unless prev_node_offset.nil?
                prev_node_offset = offset
            when 'goto'
                # Declare start block early if it doesn't exist already.
                if prev_node_offset.nil?
                    # bb start block
                    puts "      RIO_#{scrname}_0x#{offset.to_s(16)} [label=\"start\"];" 
                    prev_node_offset = offset
                end
                # Connect previous node directly to the procedure
                edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{args[0].upcase()}_0x0 [color=\"cyan\"];"
            when 'call'
                # Define call node
                puts "      RIO_#{scrname}_0x#{offset.to_s(16)} [label=\"call #{args[0].upcase()}\", color=\"green\"];"
                # Connect to previous node
                edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{scrname}_0x#{offset.to_s(16)} [color=\"blue\"];" unless prev_node_offset.nil?
                prev_node_offset = offset
            end
            if prev_node_offset.nil?
                # bb start block
                puts "      RIO_#{scrname}_0x#{offset.to_s(16)} [label=\"start\"];" 
                prev_node_offset = offset
            end
        end
        # Draw the edges to other basic blocks
        case bb.type
        when 'cjmp'
            edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{scrname}_0x#{bb.jump_true.to_s(16)} [color=\"green\"];"
            edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{scrname}_0x#{bb.jump_false.to_s(16)} [color=\"red\"];"
        when 'procjump', 'ret'
            # do nothing
        else
            edges << "RIO_#{scrname}_0x#{prev_node_offset.to_s(16)} -> RIO_#{scrname}_0x#{bb.jump_true.to_s(16)} [color=\"blue\"];"
        end
        puts "    }"
    end
    puts "  }"
end
# Dump all edges
edges.each { |e| puts "  #{e}" }
puts('}')
