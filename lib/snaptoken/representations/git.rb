class Snaptoken::Representations::Git < Snaptoken::Representations::BaseRepresentation
  def save!(options = {})
    FileUtils.rm_rf(repo_path)
    FileUtils.mkdir_p(repo_path)

    FileUtils.cd(repo_path) do
      repo = Rugged::Repository.init_at(".")

      step_num = 1
      @tutorial.pages.each do |page|
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

  # Options:
  #   full_diffs: If true, diffs contain the entire file in one hunk instead of
  #     multiple contextual hunks.
  #   diffs_ignore_whitespace: If true, diffs don't show changes to lines when
  #     only the amount of whitespace is changed.
  def load!(options = {})
    git_diff_options = {}
    git_diff_options[:context_lines] = 100_000 if options[:full_diffs]
    git_diff_options[:ignore_whitespace_change] = true if options[:diffs_ignore_whitespace]

    repo = Rugged::Repository.new(repo_path)
    empty_tree = Rugged::Tree.empty(repo)

    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    walker.push(repo.branches.find { |b| b.name == "master" }.target)

    step_num = 1
    page = nil
    @tutorial.clear
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
          @tutorial << page unless page.nil?

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
    @tutorial << page unless page.nil?
    @tutorial
  end

  def copy_repo_to_step!
    FileUtils.mkdir_p(step_path)
    FileUtils.rm_rf(File.join(step_path, "."), secure: true)
    FileUtils.cd(repo_path) do
      files = Dir.glob("*", File::FNM_DOTMATCH) - [".", "..", ".git"]
      files.each do |f|
        FileUtils.cp_r(f, File.join(step_path, f))
      end
    end
  end

  def copy_step_to_repo!
    FileUtils.mv(
      File.join(repo_path, ".git"),
      File.join(repo_path, "../.gittemp")
    )
    FileUtils.rm_rf(File.join(repo_path, "."), secure: true)
    FileUtils.mv(
      File.join(repo_path, "../.gittemp"),
      File.join(repo_path, ".git")
    )
    FileUtils.cd(step_path) do
      files = Dir.glob("*", File::FNM_DOTMATCH) - [".", ".."]
      files.each do |f|
        FileUtils.cp_r(f, File.join(repo_path, f))
      end
    end
  end

  def repo_path
    File.join(@tutorial.config[:path], ".leg/repo")
  end

  def remaining_commits
    if File.exist?(remaining_commits_path)
      File.readlines(remaining_commits_path).map(&:strip).reject(&:empty?)
    else
      []
    end
  end

  def remaining_commits=(commits)
    if commits && !commits.empty?
      File.write(remaining_commits_path, commits.join("\n"))
    else
      FileUtils.rm_f(remaining_commits_path)
    end
  end

  private

  def step_path
    File.join(@tutorial.config[:path], "step")
  end

  def remaining_commits_path
    File.join(@tutorial.config[:path], ".leg/remaining_commits")
  end

  def modified_at
    if File.exist? repo_path
      repo = Rugged::Repository.new(repo_path)
      if master = repo.branches.find { |b| b.name == "master" }
        master.target.time
      end
    end
  end

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
    if @tutorial.config[:repo_author_name]
      options[:author] = {
        name: @tutorial.config[:repo_author_name],
        email: @tutorial.config[:repo_author_email],
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
