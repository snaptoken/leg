class Snaptoken::Representations::Litdiff < Snaptoken::Representations::BaseRepresentation
  def save!(options = {})
    FileUtils.mkdir_p(path)
    FileUtils.rm_rf(File.join(path, "."), secure: true)

    step_num = 1
    @tutorial.pages.each.with_index do |page, page_idx|
      output = ""
      page.steps.each do |step|
        output << step.text << "\n\n" unless step.text.empty?
        output << "~~~ #{step.summary}\n"
        output << step.to_patch(unchanged_char: "|") << "\n"

        yield step_num if block_given?
        step_num += 1
      end
      output << page.footer_text << "\n" if page.footer_text

      filename = page.filename + ".litdiff"
      filename = "%02d.%s" % [page_idx + 1, filename] if @tutorial.pages.length > 1

      File.write(File.join(path, filename), output)
    end
  end

  def load!(options = {})
    step_num = 1
    @tutorial.clear
    Dir[File.join(path, "*.litdiff")].sort_by { |f| File.basename(f).to_i }.each do |diff_path|
      filename = File.basename(diff_path).sub(/\.litdiff$/, "").sub(/^\d+\./, "")
      page = Snaptoken::Page.new(filename)
      File.open(diff_path, "r") do |f|
        cur_text = ""
        cur_diff = nil
        cur_summary = nil
        while line = f.gets
          if line.start_with? "~~~"
            cur_summary = (line[3..-1] || "").strip
            cur_diff = ""
          elsif cur_diff
            if line.chomp.empty?
              step_diffs = Snaptoken::Diff.parse(cur_diff)
              page << Snaptoken::Step.new(step_num, cur_summary, cur_text.strip, step_diffs)

              yield step_num if block_given?
              step_num += 1

              cur_text = ""
              cur_summary = nil
              cur_diff = nil
            else
              cur_diff << line.sub(/^\|/, " ")
            end
          else
            cur_text << line
          end
        end
        if cur_diff
          step_diffs = Snaptoken::Diff.parse(cur_diff)
          page << Snaptoken::Step.new(step_num, cur_summary, cur_text.strip, step_diffs)
        elsif !cur_text.strip.empty?
          page.footer_text = cur_text.strip
        end
      end
      @tutorial << page
    end
    @tutorial
  end

  def path
    File.join(@tutorial.config[:path], "doc")
  end

  private

  def modified_at
    if File.exist? path
      Dir[File.join(path, "**/*")].map { |f| File.mtime(f) }.max
    end
  end
end
