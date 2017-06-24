require 'optparse'
require 'md2conflu/client'

opts = {}

OptionParser.new do |opt|
  opt.on('-f VALUE', '--file VALUE', 'markdown file to be converted'){ |v|
    opts[:file] = v
  }

  opt.parse!(ARGV)

  plugin_path = File.join(File.dirname(__FILE__), '../plugin')

  input_plugin = []
  output_plugin = []
  Dir.entries(plugin_path).sort.each do |fname|
    /^in_(.*)\.rb/.match(fname) { |md|
      input_plugin.push(md[1]) if opts.has_key?(md[1].to_sym)
    }
    /^out_(.*)\.rb/.match(fname) { |md|
      output_plugin.push(md[1]) if opts.has_key?(md[1].to_sym)
    }
  end
  if input_plugin.empty?
    if ARGV.empty?
      input_plugin.push('stdin')
      opts[:stdin] = STDIN.read
    else
      input_plugin.push('argv')
      opts[:argv] = ARGV[0]
    end
  end
  if output_plugin.empty?
    output_plugin.push('stdout')
    opts[:stdout] = true
  end
  if input_plugin.length > 1 or output_plugin.length > 1
    raise "Too much options."
  end

  client = Md2conflu::Client.new
  client.load_input_plugin(input_plugin[0], opts)
  client.load_output_plugin(output_plugin[0], opts)
  client.run
end
