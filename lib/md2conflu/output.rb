module Md2conflu
  class Output
    def load_opts(opts)
      raise "Called abstract method: load_opts"
    end
    def output
      raise "Called abstract method: output"
    end
  end
end