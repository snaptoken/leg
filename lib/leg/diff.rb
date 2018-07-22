module Leg
  class Diff
    attr_accessor :filename, :is_new_file, :lines

    def initialize(filename = nil, is_new_file = false, lines = [])
      @filename = filename
      @is_new_file = is_new_file
      @lines = lines
    end

    def clone
      Leg::Diff.new(@filename.dup, @is_new_file, @lines.map(&:clone))
    end

    def clone_empty
      Leg::Diff.new(@filename.dup, @is_new_file, [])
    end

    # Append a Line to the Diff.
    def <<(line)
      unless line.is_a? Leg::Line
        raise ArgumentError, "expected a Line"
      end
      @lines << line
      self
    end

    def to_patch(options = {})
      patch = ""
      patch += "diff --git a/#{@filename} b/#{@filename}\n" unless options[:strip_git_lines]
      if @is_new_file
        patch += "new file mode 100644\n" unless options[:strip_git_lines]
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
        if line =~ /^--- (.+)$/
          cur_diff = Leg::Diff.new
          if $1 == '/dev/null'
            cur_diff.is_new_file = true
          end
          diffs << cur_diff
          in_diff = false
        elsif line =~ /^\+\+\+ (.+)$/
          cur_diff.filename = $1.split("/")[1..-1].join("/")
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
            line_nums = [old_line_num, new_line_num]
            old_line_num += 1
            new_line_num += 1
            cur_diff << Leg::Line::Unchanged.new(line[1..-1], line_nums)
          when '+'
            line_nums = [nil, new_line_num]
            new_line_num += 1
            cur_diff << Leg::Line::Added.new(line[1..-1], line_nums)
          when '-'
            line_nums = [old_line_num, nil]
            old_line_num += 1
            cur_diff << Leg::Line::Removed.new(line[1..-1], line_nums)
          end
        else
          in_diff = false
        end
      end

      diffs
    end

    private

    # :S
    def hunk_header(hunk)
      old_line, new_line = hunk.first.line_numbers
      old_line ||= 1
      new_line ||= 1

      old_count = hunk.count { |line| [Leg::Line::Removed, Leg::Line::Unchanged].include? line.class }
      new_count = hunk.count { |line| [Leg::Line::Added, Leg::Line::Unchanged].include? line.class }

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
        case line
        when Leg::Line::Unchanged
          cur_line_nums[0] = cur_line_nums[0].nil? ? line.line_numbers[0] : (cur_line_nums[0] + 1)
          cur_line_nums[1] = cur_line_nums[1].nil? ? line.line_numbers[1] : (cur_line_nums[1] + 1)
        when Leg::Line::Added
          cur_line_nums[1] = cur_line_nums[1].nil? ? line.line_numbers[1] : (cur_line_nums[1] + 1)
        when Leg::Line::Removed
          cur_line_nums[0] = cur_line_nums[0].nil? ? line.line_numbers[0] : (cur_line_nums[0] + 1)
        when Leg::Line::Folded
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
end
