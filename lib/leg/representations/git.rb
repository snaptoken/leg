module Leg
  module Representations
    class Git < BaseRepresentation
      def save!(tutorial, options = {})
        FileUtils.rm_rf(repo_path)
        FileUtils.mkdir_p(repo_path)

        FileUtils.cd(repo_path) do
          repo = Rugged::Repository.init_at(".")

          step_num = 1
          tutorial.pages.each do |page|
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

          repo.checkout_head(strategy: :force) if repo.branches["master"]
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

        page = nil
        tutorial = Leg::Tutorial.new(@config)
        each_step(git_diff_options) do |step_num, commit, summary, text, patches|
          if patches.empty?
            if summary =~ /^~~~ (.+)$/
              tutorial << page unless page.nil?

              page = Leg::Page.new($1)
              page.footer_text = text unless text.empty?
            else
              puts "Warning: ignoring empty commit."
            end
          else
            patch = patches.map(&:to_s).join("\n")
            step_diffs = Leg::Diff.parse(patch)

            page ||= Leg::Page.new
            page << Leg::Step.new(step_num, summary, text, step_diffs)

            yield step_num if block_given?
          end
        end
        tutorial << page unless page.nil?
        tutorial
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
        File.join(@config.path, ".leg/repo")
      end

      def repo
        @repo ||= Rugged::Repository.new(repo_path)
      end

      def each_commit(options = {})
        walker = Rugged::Walker.new(repo)
        walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)

        master_commit = repo.branches["master"].target
        walker.push(master_commit)

        return [] if master_commit.oid == options[:after]
        walker.hide(options[:after]) if options[:after]

        return walker.to_a if not block_given?

        walker.each do |commit|
          yield commit
        end
      end

      alias_method :commits, :each_commit

      def each_step(git_diff_options = {})
        empty_tree = Rugged::Tree.empty(repo)
        step_num = 1
        each_commit do |commit|
          commit_message = commit.message.strip
          summary = commit_message.lines.first.strip
          text = (commit_message.lines[2..-1] || []).join.strip
          next if commit_message == "-"
          commit_message = "" if commit_message == "~"
          last_commit = commit.parents.first
          diff = (last_commit || empty_tree).diff(commit, git_diff_options)
          patches = diff.each_patch.to_a

          if patches.empty?
            yield nil, commit, summary, text, patches
          else
            yield step_num, commit, summary, text, patches
            step_num += 1
          end
        end
      end

      def init!
        FileUtils.mkdir_p(repo_path)
        FileUtils.cd(repo_path) { `git init` }
      end

      def checkout!(step_number)
        each_step do |cur_step, commit|
          if cur_step == step_number
            FileUtils.cd(repo_path) { `git checkout #{commit.oid} 2>/dev/null` }
            save_state(load_state.step!(step_number))
            copy_repo_to_step!
            return true
          end
        end
      end

      def commit!(options = {})
        copy_step_to_repo!
        remaining_commits = repo.branches["master"] ? commits(after: repo.head.target.oid).map(&:oid) : []
        FileUtils.cd(repo_path) do
          `git add -A`

          cmd = ["git", "commit", "-q"]
          cmd << "--amend" if options[:amend]
          cmd << "-m" << options[:message] if options[:message]
          cmd << "--no-edit" if options[:use_default_message] && options[:amend]
          cmd << "-m" << "Untitled step" if options[:use_default_message] && !options[:amend]
          system(*cmd)
        end
        if options[:amend]
          save_state(load_state.amend!)
        else
          save_state(load_state.add_commit!)
        end
        if options[:no_rebase]
          save_remaining_commits(remaining_commits)
          true
        else
          rebase!(remaining_commits)
        end
      end

      def resolve!
        copy_step_to_repo!
        FileUtils.cd(repo_path) do
          `git add -A`
          `git -c core.editor=true cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits --continue 2>/dev/null`
        end
        rebase!(load_remaining_commits)
      end

      def rebase_remaining!
        rebase!(load_remaining_commits)
      end

      def rebase!(remaining_commits)
        FileUtils.cd(repo_path) do
          remaining_commits.each.with_index do |commit, commit_idx|
            `git cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits #{commit} 2>/dev/null`

            if not $?.success?
              copy_repo_to_step!
              save_remaining_commits(remaining_commits[(commit_idx+1)..-1])
              save_state(load_state.conflict!)
              return false
            end
          end
        end

        save_remaining_commits(nil)
        save_state(nil)

        repo.references.update(repo.branches["master"], repo.head.target_id)
        repo.head = "refs/heads/master"

        copy_repo_to_step!

        true
      end

      def reset!
        save_state(nil)
        save_remaining_commits(nil)
        FileUtils.cd(repo_path) do
          `git cherry-pick --abort 2>/dev/null`
        end
        repo.head = "refs/heads/master"
        repo.checkout_head(strategy: :force)
        copy_repo_to_step!
      end

      def state
        load_state
      end

      private

      def step_path
        File.join(@config.path, "step")
      end

      def remaining_commits_path
        File.join(@config.path, ".leg/remaining_commits")
      end

      def modified_at
        if File.exist? repo_path
          repo = Rugged::Repository.new(repo_path)
          if master = repo.branches["master"]
            master.target.time
          end
        end
      end

      def state_path
        File.join(@config.path, ".leg/state.yml")
      end

      def load_state
        @state ||=
          if File.exist?(state_path)
            YAML.load_file(state_path)
          else
            State.new
          end
      end

      def save_state(state)
        @state = state
        if state.nil?
          FileUtils.rm_f(state_path)
        else
          File.write(state_path, state.to_yaml)
        end
      end

      def load_remaining_commits
        if File.exist?(remaining_commits_path)
          File.readlines(remaining_commits_path).map(&:strip).reject(&:empty?)
        else
          []
        end
      end

      def save_remaining_commits(remaining_commits)
        if remaining_commits && !remaining_commits.empty?
          File.write(remaining_commits_path, remaining_commits.join("\n"))
        else
          FileUtils.rm_f(remaining_commits_path)
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
        if @config.options[:repo_author_name]
          options[:author] = {
            name: @config.options[:repo_author_name],
            email: @config.options[:repo_author_email],
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

      class State
        attr_accessor :step_number, :operation, :args, :conflict

        def initialize
          @step_number = nil
          @operation = nil
          @args = []
          @conflict = false
        end

        def step!(step_number)
          @step_number = step_number
          self
        end

        def add_commit!
          if @operation.nil?
            @operation = :commit
            @args = [1, false]
          elsif @operation == :commit
            @args[0] += 1
          else
            raise "@operation must be :commit or nil"
          end
          self
        end

        def amend!
          if @operation.nil?
            @operation = :commit
            @args = [0, true]
          elsif @operation == :commit
            @args[1] = true
          else
            raise "@operation must be :commit or nil"
          end
          self
        end

        def conflict!
          @conflict = true
          self
        end
      end
    end
  end
end
