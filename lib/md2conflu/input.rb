module Md2conflu
  class Input
    def load_opts(opts)
      raise "Called abstract method: load_opts"
    end
    def input
      raise "Called abstract method: input"
    end
  end
end
