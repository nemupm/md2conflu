require 'md2conflu/parser'
require 'md2conflu/util/common'

module Md2conflu
  class Client
    include Md2conflu::Util::Common
    def load_input_plugin(plugin_name, opts = nil)
      plugin_path = File.join(File.dirname(__FILE__), 'plugin')
      require File.join(plugin_path, 'in_' + plugin_name)
      classname = to_classname(File.join('md2conflu/plugin', 'in_' + plugin_name))
      @input_plugin = Object.const_get(classname).new
      @input_plugin.load_opts(opts)
    end

    def load_output_plugin(plugin_name, opts = nil)
      plugin_path = File.join(File.dirname(__FILE__), 'plugin')
      require File.join(plugin_path, 'out_' + plugin_name)
      classname = to_classname(File.join('md2conflu/plugin', 'out_' + plugin_name))
      @output_plugin = Object.const_get(classname).new
      @output_plugin.load_opts(opts)
    end

    def run
      input = @input_plugin.input
      output = Parser.parse(input)
      @output_plugin.output(output)
    end
  end
end
