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
end

