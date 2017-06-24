require 'md2conflu/input'

module Md2conflu
  module Plugin
    class InStdin < Input
      def load_opts(opts)
        @stdin = opts[:stdin]
      end
      def input
        @stdin
      end
    end
  end
end