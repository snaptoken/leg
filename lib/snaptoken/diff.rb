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

      elsif line =~ /^@@ -(\d+)(,\d+)? \+(\d+)(,\d+)? @@/
        # TODO: somehow preserve function name that comes to the right of the @@ header?
      elsif in_diff && [' ', '|', '+', '-'].include?(line[0])
        when ' ', '|'
          line_nums = [nil, new_line_num]
          line_nums = [old_line_num, nil]

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