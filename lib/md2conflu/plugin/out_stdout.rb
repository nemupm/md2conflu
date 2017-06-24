require 'md2conflu/output'

module Md2conflu
  module Plugin
    class OutStdout < Output
      def load_opts(opts)
      end
      def output(output)
        puts output
      end
    end
  end
end