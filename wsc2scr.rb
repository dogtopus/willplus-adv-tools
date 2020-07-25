#!/usr/bin/env ruby

if ARGV.length<2
    puts 'Usage: wsc2scr <Input File> <Output File>'
    exit 1
end

File.open(ARGV[0],'rb') do |f1|
    File.open(ARGV[1],'wb') do |f2|
    f1.each_byte{|b|f2.write (((b>>2)|(b<<6))&255).chr}
    end
end

