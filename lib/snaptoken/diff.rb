class Snaptoken::Diff
  attr_accessor :filename, :is_new_file, :lines, :syntax_highlighted

  def initialize(filename = nil, is_new_file = false, lines = [])
    @filename = filename
    @is_new_file = is_new_file
    @lines = lines
    @syntax_highlighted = false
  end

  # Append a DiffLine to the Diff.
  def <<(diff_line)
    unless diff_line.is_a? Snaptoken::DiffLine
      raise ArgumentError, "expected a DiffLine"
    end
    @lines << diff_line
    self
  end

  def to_patch(options = {})
    patch = "diff --git a/#{@filename} b/#{@filename}\n"
    if @is_new_file
      patch += "new file mode 100644\n"
      patch += "--- /dev/null\n"
    else
      patch += "--- a/#{@filename}\n"
    end
    patch += "+++ b/#{@filename}\n"

    find_hunks.each do |hunk|
      patch += hunk_header(hunk)
      hunk.each do |line|
        patch += line.to_patch(options)
      end
    end

    patch
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
      elsif line =~ /^@@ -(\d+)(,\d+)? \+(\d+)(,\d+)? @@/
        # TODO: somehow preserve function name that comes to the right of the @@ header?
        in_diff = true
        old_line_num = $1.to_i
        new_line_num = $3.to_i
      elsif in_diff && line[0] == '\\'
        # Ignore "\ No newline at end of file".
      elsif in_diff && [' ', '|', '+', '-'].include?(line[0])
        case line[0]
        when ' ', '|'
          type = :unchanged
          line_nums = [old_line_num, new_line_num]
          old_line_num += 1
          new_line_num += 1
        when '+'
          type = :added
          line_nums = [nil, new_line_num]
          new_line_num += 1
        when '-'
          type = :removed
          line_nums = [old_line_num, nil]
          old_line_num += 1
        end

        cur_diff << Snaptoken::DiffLine.new(type, line[1..-1], line_nums)
      else
        in_diff = false
      end
    end

    diffs
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

  SYNTAX_HIGHLIGHTER = HTMLLineByLine.new(Rouge::Formatters::HTML.new)

  def syntax_highlight!
    return if @syntax_highlighted
    code = @lines.map(&:source).join("\n")
    lexer = Rouge::Lexer.guess(filename: @filename, source: code)
    SYNTAX_HIGHLIGHTER.format(lexer.lex(code)).lines.each.with_index do |line_hl, idx|
      @lines[idx].source = line_hl
    end
    @syntax_highlighted = true
  end

  private

  # :S
  def hunk_header(hunk)
    old_line, new_line = hunk.first.line_numbers
    old_line ||= 1
    new_line ||= 1

    old_count = hunk.count { |line| [:removed, :unchanged].include? line.type }
    new_count = hunk.count { |line| [:added, :unchanged].include? line.type }

    old_line = 0 if old_count == 0
    new_line = 0 if new_count == 0

    "@@ -#{old_line},#{old_count} +#{new_line},#{new_count} @@\n"
  end

  # :(
  def find_hunks
    raise "can't create patch from empty diff" if @lines.empty?
    hunks = []
    cur_hunk = [@lines.first]
    cur_line_nums = @lines.first.line_numbers.dup
    @lines[1..-1].each do |line|
      case line.type
      when :unchanged
        cur_line_nums[0] = cur_line_nums[0].nil? ? line.line_numbers[0] : (cur_line_nums[0] + 1)
        cur_line_nums[1] = cur_line_nums[1].nil? ? line.line_numbers[1] : (cur_line_nums[1] + 1)
      when :added
        cur_line_nums[1] = cur_line_nums[1].nil? ? line.line_numbers[1] : (cur_line_nums[1] + 1)
      when :removed
        cur_line_nums[0] = cur_line_nums[0].nil? ? line.line_numbers[0] : (cur_line_nums[0] + 1)
      when :folded
        raise "can't create patch from diff with folded lines"
      end

      old_match = (line.line_numbers[0].nil? || line.line_numbers[0] == cur_line_nums[0])
      new_match = (line.line_numbers[1].nil? || line.line_numbers[1] == cur_line_nums[1])

      if !old_match || !new_match
        hunks << cur_hunk

        cur_hunk = []
        cur_line_nums = line.line_numbers.dup
      end

      cur_hunk << line
    end
    hunks << cur_hunk
    hunks
  end
end
