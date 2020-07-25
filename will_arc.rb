#!/usr/bin/env ruby
require 'stringio'
class ARC
    def initialize(filename)
        @filename=filename
        load_list
    end

    def load_list
        @files={}
        File.open(@filename,'rb') do |arc|
            type_n=arc.read(4).unpack('L<')[0]
            # Z4: type_name; L<: length; L<: offset
            type_list=type_n.times.map { arc.read(12).unpack('Z4L<2') } 
            type_list.each do |type|
                arc.seek type[2]
                type[1].times do 
                    # Z9: sub_file; L<: length; L<: offset
                    ft=arc.read(17).unpack('Z9L<2')
                    fn=(ft.shift << ".#{type[0]}")
                    @files[fn]=ft
                end
            end
        end
    end

    def each_file
        @files.each { |fn,ft| yield fn }
    end

    def load(filename)
        raise Errno::ENOENT filename if !(@files[filename])
        (length,offset)=@files[filename]
        File.open(@filename,'rb') do |arc|
            arc.seek offset
            arc.read length
        end
    end

    def load_to_io(filename)
        StringIO.new load(filename)
    end

    attr_reader :filename
    attr_reader :files
    private :load_list
end

require 'fileutils'

->(){puts "Usage: #{$0} <arc> <dir>";exit 255}.call if ARGV.length<2
arc=ARC.new(ARGV[0])
FileUtils.mkdir_p(ARGV[1])
arc.each_file do |fn| 
    File.open(File.join(ARGV[1],fn),'wb'){|f|f.write(arc.load(fn))}
end
