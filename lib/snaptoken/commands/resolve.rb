class Snaptoken::Commands::Resolve < Snaptoken::Commands::BaseCommand
  def self.name
    "resolve"
  end

  def self.summary
    "Continue rewriting steps after resolving a merge conflict."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    @git.copy_step_to_repo!

    FileUtils.cd(@git.repo_path) do
      `git add -A`
      `git -c core.editor=true cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits --continue`

      commits = @git.remaining_commits
      commits.each.with_index do |commit, commit_idx|
        `git cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits #{commit}`

        if not $?.success?
          @git.copy_repo_to_step!
          @git.remaining_commits = commits[(commit_idx+1)..-1]

          puts "Looks like you have a conflict to resolve!"
          exit
        end
      end

      @git.repo.references.update(@git.repo.branches["master"], @git.repo.head.target_id)
      @git.repo.head = "refs/heads/master"

      git_to_litdiff!

      @git.remaining_commits = nil

      puts "Success!"
    end
  end
end
