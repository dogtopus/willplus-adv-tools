#!/usr/bin/env ruby
require_relative 'opcode'

def grouping_options(args)
    result = []
    (args.length / 7).times do |i|
        opt = args[(i * 7)..((i + 1) * 7)]
        opt[1].encode!('utf-8', 'big5')
        result << opt
    end
    return result
end

puts('digraph d0t {')
ARGV.each do |fn|
    RIOOpCode.decode_script(IO.binread(fn), true).each do |line|
        scrname = File.basename(fn).split('.')[0]
        case line[1]
        when 'goto'
            puts("  s_#{scrname} -> s_#{line[2]};")
        when 'option'
            opts = grouping_options(line[2..-1])
            opts.each { |o| puts("  s_#{scrname} -> s_#{o[6]} [label=\"#{o[1]}\"];") }
        end
    end
end
puts('}')
