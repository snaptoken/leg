class Snaptoken::Diff
  attr_accessor :filename, :is_new_file, :lines

  def initialize(filename = nil, is_new_file = false, lines = [])
    @filename = filename
    @is_new_file = is_new_file
    @lines = lines
  end

  # Append a DiffLine to the Diff.
  def <<(diff_line)
    unless diff_line.is_a? Snaptoken::DiffLine
      raise ArgumentError, "expected a DiffLine"
    end
    @lines << diff_line
    self
  end

  # Parse a git diff and return an array of Diff objects, one for each file in
  # the git diff.
  def self.parse(git_diff)
    in_diff = false
    old_line_num = nil
    new_line_num = nil
    cur_diff = nil
    diffs = []

    git_diff.lines.each do |line|
      if line =~ /^diff --git (\S+) (\S+)$/
        filename = $2.split("/")[1..-1].join("/")
        cur_diff = Snaptoken::Diff.new(filename)
        diffs << cur_diff
        in_diff = false
      elsif !in_diff && line.start_with?('new file')
        cur_diff.is_new_file = true
      elsif line =~ /^@@ -(\d+)(,\d+)? \+(\d+)(,\d+)? @@$/
        in_diff = true
        old_line_num = $1.to_i
        new_line_num = $3.to_i
      elsif in_diff && line[0] == '\\'
        # Ignore "\ No newline at end of file".
      elsif in_diff && [' ', '+', '-'].include?(line[0])
        case line[0]
        when ' '
          type = :unchanged
          line_nums = [old_line_num, new_line_num]
          old_line_num += 1
          new_line_num += 1
        when '+'
          type = :added
          line_nums = [new_line_num]
          new_line_num += 1
        when '-'
          type = :removed
          line_nums = [old_line_num]
          old_line_num += 1
        end

        cur_diff << Snaptoken::DiffLine.new(type, line[1..-1], line_nums)
      else
        in_diff = false
      end
    end

    diffs
  end

  def to_html(config, step_num, step_name)
    formatter = Rouge::Formatters::HTML.new
    formatter = HTMLLineByLine.new(formatter)

    file_contents = @lines.map(&:line).join("\n")
    lexer = Rouge::Lexer.guess(filename: @filename, source: file_contents)
    code_hl = formatter.format(lexer.lex(file_contents)).lines.each(&:chomp!)

    html = ""
    html << "<div class=\"diff\">\n"
    html << "<div class=\"diff-header\">\n"
    html << "  <div class=\"step-filename\"><a href=\"https://github.com/snaptoken/#{config[:name]}-src/blob/#{step_name}/#{@filename}\">#{@filename}</a></div>\n"
    html << "  <div class=\"step-number\">Step #{step_num}</div>\n"
    html << "  <div class=\"step-name\"><a href=\"https://github.com/snaptoken/#{config[:name]}-src/tree/#{step_name}\">#{step_name}</a></div>\n"
    html << "</div>"
    html << "<pre class=\"highlight\"><code>"

    @lines.each.with_index do |diff_line, idx|
      if diff_line.type == :folded
        summary = diff_line.line_numbers.map { |n| code_hl[n] }.join(" &hellip; ").gsub("\n", "")
        html << "<div class=\"line folded\">#{summary}</div>"
      else
        tag = {unchanged: :div, added: :ins, removed: :del}[diff_line.type]
        tag = :div if self.is_new_file
        html << "<#{tag} class=\"line\">#{code_hl[idx]}</#{tag}>"
      end
    end

    html << "</code></pre>\n"

    #unless step.data.empty?
    #  html << "<div class=\"diff-footer\">\n"
    #  step.data.each do |tag|
    #    html << "  <div class=\"diff-tag-#{tag}\">#{config[:tags][tag.to_sym]}</div>\n"
    #  end
    #  html << "</div>\n"
    #end

    html << "</div>\n"

    html
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
end

