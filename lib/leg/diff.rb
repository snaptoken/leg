    attr_accessor :filename, :is_new_file, :lines
      Leg::Diff.new(@filename.dup, @is_new_file, @lines.map(&:clone))
      Leg::Diff.new(@filename.dup, @is_new_file, [])
      patch = ""
      patch += "diff --git a/#{@filename} b/#{@filename}\n" unless options[:strip_git_lines]
        patch += "new file mode 100644\n" unless options[:strip_git_lines]
        patch += "--- #{'a/' unless options[:strip_git_lines]}#{@filename}\n"
      patch += "+++ #{'b/' unless options[:strip_git_lines]}#{@filename}\n"
        if line =~ /^--- (.+)$/
          cur_diff = Leg::Diff.new
          if $1 == '/dev/null'
            cur_diff.is_new_file = true
          end
        elsif line =~ /^\+\+\+ (.+)$/
          cur_diff.filename = $1.strip.sub(/^b\//, '')
            cur_diff << Leg::Line::Unchanged.new(line[1..-1], line_nums)
            cur_diff << Leg::Line::Added.new(line[1..-1], line_nums)
            cur_diff << Leg::Line::Removed.new(line[1..-1], line_nums)
      old_count = hunk.count { |line| [Leg::Line::Removed, Leg::Line::Unchanged].include? line.class }
      new_count = hunk.count { |line| [Leg::Line::Added, Leg::Line::Unchanged].include? line.class }
        case line
        when Leg::Line::Unchanged
        when Leg::Line::Added
        when Leg::Line::Removed
        when Leg::Line::Folded