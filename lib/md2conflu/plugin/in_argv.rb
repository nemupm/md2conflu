require 'md2conflu/input'

module Md2conflu
  module Plugin
    class InArgv < Input
      def load_opts(opts)
        @stdin = opts[:argv]
      end
      def input
        @stdin
      end
    end
  end
end
