require "Parslet"
require "pp"

module Md2conflu
  class Parser
    def self.parse(input)
      parser = MarkdownParser.new
      transf = ConfluenceTransform.new

      begin
        parse_result = parser.parse(input)
        md = transf.apply(parse_result)
        markup = puts_hash(md)
        markup
      rescue Parslet::ParseFailed => failure
        raise failure.cause.ascii_tree
      end
    end

    def self.puts_hash(data)
      if data.is_a? Hash
        str = ""
        data.each_value{|e|
          str += puts_hash(e)
        }
        str
      elsif data.is_a? Array
        str = ""
        data.each{|e|
          str += puts_hash(e)
        }
        str
      elsif data.is_a? String
        data
      elsif data.is_a? Parslet::Slice
        data.str
      elsif data.is_a? NilClass
        ""
      else
        raise "unexpected element in hash of markdown"
      end
    end
  end

  class MarkdownParser < Parslet::Parser
    root :document

    rule :document do
      any.absent?.as(:blank) | (block | blank).repeat.as(:document)
    end

    rule :block do
      fenced_code_block |
          hrule |
          atx_header |
          quote |
          list |
          # indented_code |
          link_ref_def |
          setext_header |
          paragraph >>
              newline
    end

    def block_repeat(body, delimiter, secondary=body)
      (body.repeat(1,1) >> (delimiter >> secondary).repeat)
    end

    rule :paragraph do
      block_repeat(inline, newline, line).as(:paragraph)
    end

    rule :line do
      dynamic do |s, c|
        begin
          str(c.captures[:marker]) >> scope { inline } # TODO: should be line, recursing quote levels
        rescue Parslet::Scope::NotFound => e
          any.present? >> inline
        end
      end
    end

    rule :setext_header do
      (opt_indent >> inline >> newline >>
          opt_indent >> setext_grade).as(:setext_header)
    end

    rule :setext_grade do
      str('=').repeat(1).as(:grade_1) | str('-').repeat(1).as(:grade_2)
    end

    rule :quote do
      ((marker >> space.maybe).capture(:marker) >> block.repeat(1)).as(:quote)
    end

    rule :marker do
      (opt_indent >> str('>'))
    end

    rule :blank do
      (space.repeat >> line_feed.repeat(1) | space.repeat(1) >> line_feed.repeat(0)).as(:blank)
    end

    rule :list do
      ordered_list | unordered_list
    end

    rule :ordered_list do
      (opt_indent.as(:ordered_list_indent) >> match['\d+'] >> match['\.\)'] >>
          space >> inline).as(:ordered_list)
    end

    rule :unordered_list do
      (opt_indent.as(:unordered_list_indent) >> match['-+*'] >> space >> inline).as(:unordered_list) # >>
    end

    # rule :unordered_list_marker do
    #   (opt_indent >> match['-+*'] >> space.repeat(1)).capture(:unordered_list_marker)
    # end

    rule :atx_header do
      opt_indent >>
          (str('#').repeat(1, 6).as(:grade) >>
              space.repeat(1) >> inline).as(:atx_header)
    end

    # rule :indented_code do
    #   (tab >> text >> newline).repeat(1).as(:indented_code)
    # end

    rule :tab do
      str("\t") | space.repeat(4, 4)
    end

    rule :fenced_code_block do
      opt_indent >> fence.capture(:fence) >> code_style >> str("\n") >>
          dynamic do |s, c|
            (str(c.captures[:fence]).absent? >> code_text.maybe >> newline).repeat(1) >>
                str(c.captures[:fence])
          end.as(:fenced_code_block)
    end

    rule :code_style do
      match['a-z'].repeat
    end

    rule :code_text do
      (newline.absent? >>
          # delimiter.absent? >>
          any).repeat(1).as(:code_text)
    end

    rule :link_ref_def do
      opt_indent >> (str('[') >> (str(']').absent? >> any).repeat.as(:ref) >> str(']:') >>
          space >> (space.absent? >> any).repeat.as(:destination) >>
          space >> match['\'"'].capture(:quote) >>
          dynamic do |s, c|
            (str(c.captures[:quote]).absent? >> any).repeat(1).as(:title) >>
                str(c.captures[:quote])
          end).as(:ref_def)
    end

    rule :opt_indent do
      space.repeat(0, 9)
    end

    rule :fence do
      str('`').repeat(3) | str('~').repeat(3)
    end

    rule :inline do
      (escaped | entity | code_span |
          # delimiter |
          link | image | autolink | text).repeat(1).as(:inline)
    end

    rule :autolink do
      (str('<') >> (str('>').absent? >> any).repeat(1).as(:destination) >>
          str('>')).as(:link)
    end

    rule :image do
      (str('![') >> (str(']').absent? >> any).repeat.as(:description) >> str('](') >>
          (space.absent? >> any).repeat.as(:source) >>
          (space >> match['\'"'].capture(:quote) >>
              dynamic do |s, c|
                (str(c.captures[:quote]).absent? >> any).repeat(1).as(:title) >>
                    str(c.captures[:quote])
              end).maybe >> str(')')).as(:image)
    end

    rule :link do
      (str('[') >> (str(']').absent? >> any).repeat.as(:text) >> str('](') >>
          (space.absent? >> any).repeat.as(:destination) >>
          (space >> match['\'"'].capture(:quote) >>
              dynamic do |s, c|
                (str(c.captures[:quote]).absent? >> any).repeat(1).as(:title) >>
                    str(c.captures[:quote])
              end).maybe >> str(')')).as(:link)
    end

    # rule :delimiter do
    #   left_delimiter | right_delimiter
    # end

    # rule :left_delimiter do
    #   (delimiter_ >> flank).as(:left_delimiter)
    # end

    # rule :right_delimiter do
    #   (flank >> delimiter_).as(:right_delimiter)
    # end

    # rule :delimiter_ do
    #   str('*').repeat(1, 3) | str('_').repeat(1, 3)
    # end

    rule :flank do
      (any.present? >> str(' ').absent?)
    end

    rule :entity do
      (html_entity | decimal_entity | hex_entity).as(:entity)
    end

    rule :html_entity do
      str('&') >> (str(';').absent? >> match['a-zA-Z'].repeat(1)) >> str(';')
    end

    rule :decimal_entity do
      str('&#') >> (str(';').absent? >> match['0-9'].repeat(1, 8)) >> str(';')
    end

    rule :hex_entity do
      str('&#') >> match['xX'] >> (str(';').absent? >> match['0-9'].repeat(1, 8)) >> str(';')
    end

    rule :code_span do
      str('`').repeat(1).capture(:backtick_string) >>
          dynamic do |s, c|
            (str(c.captures[:backtick_string]).absent? >> newline.absent? >>
                any).repeat(1).as(:code_span) >> str(c.captures[:backtick_string])
          end
    end

    rule :escaped do
      str('\\') >> any.as(:escaped) # actually only punctuation
    end

    rule :text do
      # space.absent? >>
      (newline.absent? >>
          # delimiter.absent? >>
          (str('`').absent? >> any)).repeat(1).as(:text)
    end

    rule :newline do
      (any.absent? | line_feed).as(:newline)
    end

    rule :line_feed do
      hard_break.maybe >> str("\n")
    end

    rule :hard_break do
      space.repeat(2, 2).as(:hard_break)
    end

    rule :space do
      str(' ')
    end

    rule :hrule do
      opt_indent >> (hrule_('*') | hrule_('-') | hrule_('_')).as(:hrule)
    end

    def hrule_(char)
      (str(char) >> space.repeat(0)).repeat(3)
    end
  end

  class ConfluenceTransform < Parslet::Transform

    rule(setext_header: {inline: sequence(:content), grade_1: simple(:grade_1)}) do
      "h1. #{content.join}"
    end

    rule(setext_header: {inline: sequence(:content), grade_2: simple(:grade_2)}) do
      "h2. #{content.join}"
    end

    rule(setext_header: {inline: sequence(:content), grade_3: simple(:grade_3)}) do
      "h3. #{content.join}"
    end

    rule(setext_header: {inline: sequence(:content), grade_4: simple(:grade_4)}) do
      "h4. #{content.join}"
    end

    rule(setext_header: {inline: sequence(:content), grade_5: simple(:grade_5)}) do
      "h5. #{content.join}"
    end

    rule(setext_header: {inline: sequence(:content), grade_6: simple(:grade_6)}) do
      "h6. #{content.join}"
    end

    rule(unordered_list_indent: [], inline: sequence(:content)){"* #{content.join}"}
    rule(unordered_list_indent: '  ', inline: sequence(:content)){"** #{content.join}"}
    rule(unordered_list_indent: '    ', inline: sequence(:content)){"*** #{content.join}"}
    rule(unordered_list_indent: '      ', inline: sequence(:content)){"**** #{content.join}"}

    rule(ordered_list_indent: [], inline: sequence(:content)){"* #{content.join}"}
    rule(ordered_list_indent: '  ', inline: sequence(:content)){"** #{content.join}"}
    rule(ordered_list_indent: '    ', inline: sequence(:content)){"*** #{content.join}"}
    rule(ordered_list_indent: '      ', inline: sequence(:content)){"**** #{content.join}"}

    # `code_span`
    # rule(code_span: simple(:text)) {"{{#{text}}}"}
    rule(code_span: simple(:text)) {"{code}#{text}{code}"}
    # ```fenced_code_block```
    rule(fenced_code_block: sequence(:x)) {"{code}\n#{x.join}{code}" }

    rule(text: simple(:text)) do
      "#{text}".gsub(/([\{\}\[\]])/){'\\' + $1}
    end
    rule(code_text: simple(:code_text), newline: simple(:x)) { "#{code_text}\n" }

    rule(atx_header: {grade: simple(:grade), inline: sequence(:content)}) do
      "h#{grade.size}. #{content.join}"
    end

    rule(text: simple(:x), newline: "\n") { "#{x}\n"}
    rule(newline: "\n") { "\n"}
  end
end
