#!/usr/bin/env ruby
require 'csv'
require_relative 'opcode'

STDERR.write("Parsing #{ARGV[0]}\n")
csv_str = CSV.generate do |csv| 
    RIOOpCode.decode_script(IO.binread(ARGV[0]), true).each { |line| csv << line }
end.encode('utf-8', 'big5')
puts csv_str
