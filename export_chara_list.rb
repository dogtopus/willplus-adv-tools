#!/usr/bin/env ruby

require_relative 'op2rpy_settings'

File.open(ARGV[0], 'w') do |f|
    f.puts('init:')
    O2RSettings::CHARACTER_TABLE.each do |name, display_name|
        name_actual = (O2RSettings::CHARACTER_TABLE_NS.nil?) ? name : "#{O2RSettings::CHARACTER_TABLE_NS}.#{name}"
        chardef = []
        chardef << 'define '
        chardef << name_actual
        chardef << ' = Character('
        chardef << "'#{display_name}', "
        props_output = []
        props = O2RSettings::CHARACTER_PROPS[name]
        unless props.nil?
            props.each do |key, val|
                case key
                when 'who_color'
                    props_output << "who_color='#{val}'"
                else
                    puts "Ignore unrecognized property #{key} for character #{name} (#{display_name})"
                end
            end
        end
        chardef << props_output.join(', ')
        chardef << ')'
        f.puts("  #{chardef.join('')}")
    end
end
