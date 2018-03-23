class Snaptoken::Tutorial
  attr_accessor :config
  attr_accessor :page_template, :step_template
  attr_reader :pages

  def initialize(config = {})
    @config = config
    @page_template = Snaptoken::DefaultTemplates::PAGE
    @step_template = Snaptoken::DefaultTemplates::STEP
    @pages = []
  end

  def <<(page)
    @pages << page
    self
  end

  def step(number)
    cur = 1
    @pages.each do |page|
      page.steps.each do |step|
        return step if cur == number
        cur += 1
      end
    end
  end

  def num_steps
    @pages.map(&:steps).map(&:length).sum
  end

  def transform_diffs(transformers, &progress_block)
    step_num = 1
    @pages.each do |page|
      page.steps.each do |step|
        step.diffs.map! do |diff|
          transformers.inject(diff) do |acc, transformer|
            transformer.transform(acc)
          end
        end
        progress_block.(step_num) if progress_block
        step_num += 1
      end
    end
  end

  def last_synced_at
    if File.exist?(File.join(@config[:path], ".leg/last_synced"))
      File.mtime(File.join(@config[:path], ".leg/last_synced"))
    end
  end

  def diff_modified_at
    path = File.join(@config[:path], "doc")
    if File.exist? path
      Dir[File.join(path, "**/*")].map { |f| File.mtime(f) }.max
    end
  end

  def repo_modified_at
    path = File.join(@config[:path], ".leg/repo")
    if File.exist? path
      repo = Rugged::Repository.new(path)
      if master = repo.branches.find { |b| b.name == "master" }
        master.target.time
      end
    end
  end

  def diff_modified?
    synced_at = last_synced_at
    modified_at = diff_modified_at
    return false if synced_at.nil? or modified_at.nil?

    modified_at > synced_at
  end

  def repo_modified?
    synced_at = last_synced_at
    modified_at = repo_modified_at
    return false if synced_at.nil? or modified_at.nil?

    modified_at > synced_at
  end

  def copy_repo_to_step!
    step_dir = File.join(@config[:path], "step")
    FileUtils.mkdir_p(step_dir)
    FileUtils.rm_rf(File.join(step_dir, "."), secure: true)
    FileUtils.cd(File.join(@config[:path], ".leg/repo")) do
      files = Dir.glob("*", File::FNM_DOTMATCH) - [".", "..", ".git"]
      files.each do |f|
        FileUtils.cp_r(f, File.join(step_dir, f))
      end
    end
  end

  def copy_step_to_repo!
    FileUtils.mv(
      File.join(@config[:path], ".leg/repo/.git"),
      File.join(@config[:path], ".leg/.gittemp")
    )
    FileUtils.rm_rf(File.join(@config[:path], ".leg/repo/."), secure: true)
    FileUtils.mv(
      File.join(@config[:path], ".leg/.gittemp"),
      File.join(@config[:path], ".leg/repo/.git")
    )
    FileUtils.cd(File.join(@config[:path], "step")) do
      files = Dir.glob("*", File::FNM_DOTMATCH) - [".", ".."]
      files.each do |f|
        FileUtils.cp_r(f, File.join(@config[:path], ".leg/repo", f))
      end
    end
  end

  def save_to_repo(options = {})
    path = options[:path] || File.join(@config[:path], ".leg/repo")

    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(path)

    FileUtils.cd(path) do
      repo = Rugged::Repository.init_at(".")

      step_num = 1
      pages.each do |page|
        message = "~~~ #{page.filename}"
        message << "\n\n#{page.footer_text}" if page.footer_text
        add_commit(repo, nil, message, step_num)
        page.steps.each do |step|
          message = "#{step.summary}\n\n#{step.text}".strip
          add_commit(repo, step.to_patch, message, step_num)

          yield step_num if block_given?
          step_num += 1
        end
      end

      #if options[:extra_path]
      #  FileUtils.cp_r(File.join(options[:extra_path], "."), ".")
      #  add_commit(repo, nil, "-", step_num, counter)
      #end

      repo.checkout_head(strategy: :force)
    end
  end

  def save_to_diff(options = {})
    path = options[:path] || File.join(@config[:path], "doc")

    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(path)

    step_num = 1
    @pages.each.with_index do |page, page_idx|
      output = ""
      page.steps.each do |step|
        output << step.text << "\n\n" unless step.text.empty?
        output << "~~~ #{step.summary}\n"
        output << step.to_patch(unchanged_char: "|") << "\n"

        yield step_num if block_given?
        step_num += 1
      end
      output << page.footer_text if page.footer_text
      output.chomp!

      filename = page.filename + ".litdiff"
      filename = "%02d.%s" % [page_idx + 1, filename] if @pages.length > 1

      File.write(File.join(path, filename), output)
    end
  end

  # Options:
  #   full_diffs: If true, diffs contain the entire file in one hunk instead of
  #     multiple contextual hunks.
  #   diffs_ignore_whitespace: If true, diffs don't show changes to lines when
  #     only the amount of whitespace is changed.
  def load_from_repo(options = {})
    path = options[:path] || File.join(@config[:path], ".leg/repo")

    git_diff_options = {}
    git_diff_options[:context_lines] = 100_000 if options[:full_diffs]
    git_diff_options[:ignore_whitespace_change] = true if options[:diffs_ignore_whitespace]

    repo = Rugged::Repository.new(path)
    empty_tree = Rugged::Tree.empty(repo)

    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    walker.push(repo.branches.find { |b| b.name == "master" }.target)

    step_num = 1
    page = nil
    @pages = []
    walker.each do |commit|
      commit_message = commit.message.strip
      summary = commit_message.lines.first.strip
      text = (commit_message.lines[2..-1] || []).join.strip
      next if commit_message == "-"
      commit_message = "" if commit_message == "~"
      last_commit = commit.parents.first
      diff = (last_commit || empty_tree).diff(commit, git_diff_options)
      patches = diff.each_patch.to_a

      if patches.empty?
        if summary =~ /^~~~ (.+)$/
          self << page unless page.nil?

          page = Snaptoken::Page.new($1)
          page.footer_text = text unless text.empty?
        else
          puts "Warning: ignoring empty commit."
        end
      else
        patch = patches.map(&:to_s).join("\n")
        step_diffs = Snaptoken::Diff.parse(patch)

        page ||= Snaptoken::Page.new
        page << Snaptoken::Step.new(step_num, summary, text, step_diffs)

        yield step_num if block_given?
        step_num += 1
      end
    end
    self << page unless page.nil?
    self
  end

  def load_from_diff(options = {})
    path = options[:path] || File.join(@config[:path], "doc")

    step_num = 1
    @pages = []
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
      self << page
    end
    self
  end

  private

  def add_commit(repo, diff, message, step_num)
    message ||= "~"
    message.strip!
    message = "~" if message.empty?

    if diff
      stdin = IO.popen("git apply -", "w")
      stdin.write diff
      stdin.close
    end

    index = repo.index
    index.read_tree(repo.head.target.tree) unless repo.empty?

    Dir["**/*"].each do |path|
      unless File.directory?(path)
        oid = repo.write(File.read(path), :blob)
        index.add(path: path, oid: oid, mode: 0100644)
      end
    end

    options = {}
    options[:tree] = index.write_tree(repo)
    if @config[:repo_author_name]
      options[:author] = {
        name: @config[:repo_author_name],
        email: @config[:repo_author_email],
        time: Time.now
      }
      options[:committer] = options[:author]
    end
    options[:message] = message
    options[:parents] = repo.empty? ? [] : [repo.head.target]
    options[:update_ref] = "HEAD"

    commit_oid = Rugged::Commit.create(repo, options)

    if diff
      repo.references.create("refs/tags/step-#{step_num}", commit_oid)
    end
  end
end
