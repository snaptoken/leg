class Snaptoken::Diff
  GIT_DIFF_OPTIONS = "--histogram --unified=100000 --ignore-space-change --no-index"

  attr_reader :files, :html

  def initialize(config, step_a, step_b)
    git_diff = `git diff #{GIT_DIFF_OPTIONS} #{step_a.folder_name} #{step_b.folder_name}`
    parse_git_diff(git_diff)
    @files.values.each(&:omit_adjacent_removals!)

    @html = {}
    @files.each do |filename, file|
      @html[filename] = file.to_html(config, step_b)
    end
  end

  class DiffLine
    attr_reader :type, :line
    attr_writer :type

    def initialize(type, line)
      @type = type
      @line = line
    end

    def empty!; @empty = true; end
    def empty?; @empty; end

    def omit!; @omit = true; end
    def omit?; @omit; end
  end

  class DiffSection
    attr_reader :type, :lines, :contents

    def initialize(type, line=nil)
      @type = type
      @lines = Array(line)
      @contents = []
    end

    def <<(content)
      @contents << content
    end

    def dirty!; @dirty = true; end
    def dirty?; @dirty; end
  end

  class DiffFile < DiffSection
    attr_reader :filename, :file_contents

    def initialize(filename)
      super(:file)
      @filename = filename
      @file_contents = ""
    end

    def append_line(line)
      @file_contents << line
      @file_contents << "\n" unless line.end_with? "\n"
    end

    def new_file!; @new_file = true; end
    def new_file?; @new_file; end

    def omit_adjacent_removals!
      change_chain = []
      to_render = @contents.dup
      until to_render.empty?
        cur = to_render.shift
        if cur.is_a? DiffSection
          if cur.dirty?
            to_render = cur.contents + to_render
          else
            [change_chain.first, change_chain.last].compact.each do |line|
              line.type = :nochange if line.empty?
            end
            change_chain = []
          end
        else
          if cur.type == :nochange
            [change_chain.first, change_chain.last].compact.each do |line|
              line.type = :nochange if line.empty?
            end
            change_chain = []
          else
            change_chain << cur
            if cur.type == :add
              change_chain.each { |c| c.omit! if c.type == :remove }
            elsif cur.type == :remove
              cur.omit! if change_chain.any? { |c| c.type == :add }
            end
          end
        end
      end
    end

    def to_html(config, step)
      formatter = Rouge::Formatters::HTML.new
      formatter = HTMLLineByLine.new(formatter)

      lexer = Rouge::Lexer.guess(filename: @filename, source: @file_contents)
      code_hl = formatter.format(lexer.lex(@file_contents)).lines.each(&:chomp!)

      html = ""
      html << "<div class=\"diff\">\n"
      html << "<div class=\"diff-header\">\n"
      html << "  <div class=\"step-filename\"><a href=\"https://github.com/snaptoken/#{config[:name]}-src/blob/#{step.name}/#{@filename}\">#{@filename}</a></div>\n"
      html << "  <div class=\"step-number\">Step #{step.number}</div>\n"
      html << "  <div class=\"step-name\"><a href=\"https://github.com/snaptoken/#{config[:name]}-src/tree/#{step.name}\">#{step.name}</a></div>\n"
      html << "</div>"
      html << "<pre class=\"highlight\"><code>"

      to_render = @contents.dup
      until to_render.empty?
        cur = to_render.shift
        if cur.is_a? DiffSection
          if cur.dirty?
            to_render = cur.contents + to_render
          else
            summary = cur.lines.map { |n| code_hl[n] }.join(" ... ").gsub("\n", "")
            html << "<div class=\"line folded\">#{summary}</div>"
          end
        elsif !cur.omit?
          tag = {nochange: :div, add: :ins, remove: :del}[cur.type]
          tag = :div if new_file?
          html << "<#{tag} class=\"line\">#{code_hl[cur.line]}</#{tag}>"
        end
      end
      html << "</code></pre>\n"

      unless step.data.empty?
        html << "<div class=\"diff-footer\">\n"
        step.data.each do |tag|
          html << "  <div class=\"diff-tag-#{tag}\">#{config[:tags][tag.to_sym]}</div>\n"
        end
        html << "</div>\n"
      end

      html << "</div>\n"

      html
    end
  end

  class HTMLLineByLine < Rouge::Formatter
    def initialize(formatter)
      @formatter = formatter
    end

    def stream(tokens, &b)
      token_lines(tokens) do |line|
        line.each do |tok, val|
          yield @formatter.span(tok, val)
        end
        yield "\n"
      end
    end
  end

  private

  def parse_git_diff(git_diff)
    diff_file = nil
    section_stack = nil
    line_idx = nil
    in_diff = false
    @files = {}

    git_diff.lines.each do |line|
      if line =~ /^diff --git (\S+) (\S+)$/
        diff_file = DiffFile.new($2.split("/")[2..-1].join("/"))
        @files[diff_file.filename] = diff_file
        section_stack = [diff_file]
        line_idx = -1
        in_diff = false
      elsif !in_diff && line.start_with?('new file')
        diff_file.new_file!
      elsif line.start_with? '@@'
        in_diff = true
      elsif in_diff && [' ', '+', '-'].include?(line[0])
        type = {' ' => :nochange, '+' => :add, '-' => :remove }[line[0]]
        diff_file.append_line(line[1..-1])
        line_idx += 1

        section_stack.each(&:dirty!) if type != :nochange

        if line[1..-1] =~ /^\/\*\*\* (.+) \*\*\*\/$/
          section = DiffSection.new(:comment, line_idx)
          diff_file << section
          section_stack = [diff_file, section]
        elsif line[1] =~ /\S/ && line.chomp[-1] == "{"
          section = DiffSection.new(:braces, line_idx)
          section_stack.pop if section_stack.last.type == :braces
          section_stack.last << section
          section_stack.push(section)
        end

        diff_line = DiffLine.new(type, line_idx)
        diff_line.empty! if line[1..-1].strip.empty?
        section_stack.last << diff_line

        if line[1..-1] =~ /^}( \w+)?;?$/ && section_stack.last.type == :braces
          section = section_stack.pop
          section.lines << line_idx
        end

        section_stack.each(&:dirty!) if type != :nochange
      else
        in_diff = false
      end
    end
  end
end

