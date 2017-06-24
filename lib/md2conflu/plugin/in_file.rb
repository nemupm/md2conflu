require 'md2conflu/input'

module Md2conflu
  module Plugin
    class InFile < Input
      def load_opts(opts)
        @file = opts[:file]
      end
      def input
        begin
          File.read(@file)
        rescue SystemCallError => e
          puts %Q(class=[#{e.class}] message=[#{e.message}])
        rescue IOError => e
          puts %Q(class=[#{e.class}] message=[#{e.message}])
        end
      end
    end
  end
end
