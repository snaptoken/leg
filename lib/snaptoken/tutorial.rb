class Snaptoken::Tutorial
  attr_accessor :path, :name, :title, :version
  attr_accessor :page_template, :step_template
  attr_accessor :repo_author_name, :repo_author_email, :syntax_theme

  attr_reader :pages

  def initialize(c = {})
    @path = c[:path]
    @name = c[:name] || "untitled"
    @title = c[:title] || "Untitled Tutorial"
    @version = c[:version] || "1.0"

    @page_template = c[:page_template] || Snaptoken::DefaultTemplates::PAGE
    @step_template = c[:step_template] || Snaptoken::DefaultTemplates::STEP

    @repo_author_name = c[:repo_author_name]
    @repo_author_email = c[:repo_author_email]
    @syntax_theme = c[:syntax_theme]

    @pages = []
  end

  def <<(page)
    @pages << page
    self
  end

  def step(number)
    cur = 1
    @pages.each do |page|
      page.content.each do |step_or_text|
        if step_or_text.is_a? Snaptoken::Step
          return step_or_text if cur == number
          cur += 1
        end
      end
    end
  end

  def save_to_repo(options = {})
    path = options[:path] || File.join(@path, "repo")

    FileUtils.rm_rf(path)
    FileUtils.mkdir(path)

    FileUtils.cd(path) do
      repo = Rugged::Repository.init_at(".")

      counter = 0
      step_num = 1
      pages.each do |page|
        add_commit(repo, nil, "~~~ #{page.filename}", step_num, counter)
        counter += 1
        page.content.each do |step_or_text|
          if step_or_text.is_a? Snaptoken::Step
            add_commit(repo, step_or_text.to_patch, step_or_text.text, step_num, counter)
            step_num += 1
          else
            add_commit(repo, nil, step_or_text, step_num, counter)
          end
          counter += 1
        end
      end

      if options[:extra_path]
        FileUtils.cp_r(File.join(options[:extra_path], "."), ".")
        add_commit(repo, nil, "-", step_num, counter)
      end

      repo.checkout_head(strategy: :force)
    end
  end

  def save_to_diff(options = {})
    path = options[:path] || File.join(@path, "diff")

    FileUtils.rm_rf(path)
    FileUtils.mkdir(path)

    @pages.each do |page|
      output = ""
      page.content.each do |step_or_text|
        output << "~~~\n\n" unless output.empty?
        if step_or_text.is_a? Snaptoken::Step
          output << step_or_text.text << "\n\n" unless step_or_text.text.empty?
          output << step_or_text.to_patch(unchanged_char: "|") << "\n"
        else
          output << step_or_text << "\n\n"
        end
      end
      output.chomp!

      filename = (page.filename || "steps") + ".litdiff"
      File.write(File.join(path, filename), output)
    end
  end

  # Options:
  #   full_diffs: If true, diffs contain the entire file in one hunk instead of
  #     multiple contextual hunks.
  #   diffs_ignore_whitespace: If true, diffs don't show changes to lines when
  #     only the amount of whitespace is changed.
  def load_from_repo(options = {})
    path = options[:path] || File.join(@path, "repo")

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
      next if commit_message == "-"
      last_commit = commit.parents.first
      diff = (last_commit || empty_tree).diff(commit, git_diff_options)
      patches = diff.each_patch.reject { |p| p.delta.new_file[:path] == ".dummyleg" }

      if patches.empty?
        if commit_message =~ /\A~~~ (.+)\z/
          self << page unless page.nil?

          page = Snaptoken::Page.new($1)
        else
          page ||= Snaptoken::Page.new
          page << commit_message
        end
      else
        patch = patches.map(&:to_s).join("\n")
        step_diffs = Snaptoken::Diff.parse(patch)

        #print "\r\e[K[repo/ -> build/] Step #{step_num}" unless @opts[:quiet]

        page ||= Snaptoken::Page.new
        page << Snaptoken::Step.new(step_num, commit_message, step_diffs)

        step_num += 1
      end
    end
    #print "\n" unless @opts[:quiet]
    self << page unless page.nil?
    self
  end

  def load_from_diff(options = {})
    path = options[:path] || File.join(@path, "diff")

    step_num = 1
    @pages = []
    Dir[File.join(path, "*.litdiff")].sort.each do |diff_path|
      filename = File.basename(diff_path).sub(/\.litdiff$/, "")
      page = Snaptoken::Page.new(filename)
      File.open(diff_path, "r") do |f|
        cur_message = nil
        cur_diff = nil
        while line = f.gets
          if line.strip == "~~~"
            if cur_message || cur_diff
              if !cur_diff
                page << cur_message
              else
                step_diffs = Snaptoken::Diff.parse(cur_diff)
                page << Snaptoken::Step.new(step_num, cur_message, step_diffs)

                #print "\r\e[K[diff/ -> repo/] Step #{step_num}" unless @opts[:quiet]
                step_num += 1 if cur_diff
              end

              cur_message = nil
              cur_diff = nil
            end
          elsif cur_diff
            cur_diff << line.sub(/^\|/, " ")
          elsif line =~ /^diff --git/
            cur_diff = line
          else
            cur_message ||= ""
            cur_message << line
          end
        end
        if cur_message || cur_diff
          if !cur_diff
            page << cur_message
          else
            step_diffs = Snaptoken::Diff.parse(cur_diff)
            page << Snaptoken::Step.new(step_num, cur_message, step_diffs)
          end
        end
      end
      self << page
    end
    #print "\n" unless @opts[:quiet]
    self
  end

  private

  def add_commit(repo, diff, message, step_num, counter)
    message ||= ""
    message.strip!

    if diff
      stdin = IO.popen("git apply -", "w")
      stdin.write diff
      stdin.close
    end

    index = repo.index
    index.read_tree(repo.head.target.tree) unless repo.empty?

    File.write(".dummyleg", counter)

    (Dir["**/*"] + [".dummyleg"]).each do |path|
      unless File.directory?(path)
        oid = repo.write(File.read(path), :blob)
        index.add(path: path, oid: oid, mode: 0100644)
      end
    end

    options = {}
    options[:tree] = index.write_tree(repo)
    if @repo_author_name
      options[:author] = {
        name: @repo_author_name,
        email: @repo_author_email,
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
