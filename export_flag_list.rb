#!/usr/bin/env ruby

require_relative 'op2rpy_settings'

File.open(ARGV[0], 'w') do |f|
    f.puts('python early:')
    f.puts('  WILL_FLAG_NAMES = {')
    O2RSettings::FLAG_TABLE.each do |addr, prop|
        next if prop[0].nil?
        # TODO escaping?
        f.puts("    '#{prop[0]}': #{addr},")
    end
    f.puts('  }')
end
