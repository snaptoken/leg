class Snaptoken::Commands::Commit < Snaptoken::Commands::BaseCommand
  def self.name
    "commit"
  end

  def self.summary
    "Append or insert a new step."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    repo = Rugged::Repository::new(@git.repo_path)
    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    master_commit = repo.branches["master"].target
    if master_commit.oid != repo.head.target_id
      walker.push(master_commit)
      walker.hide(repo.head.target)
      commits = walker.to_a.map(&:oid)
    else
      commits = []
    end

    @git.copy_step_to_repo!

    FileUtils.cd(@git.repo_path) do
      `git add -A`
      `git commit -m"TODO: let user specify commit message"`

      commits.each.with_index do |commit, commit_idx|
        `git cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits #{commit}`

        if not $?.success?
          @git.copy_repo_to_step!
          @git.remaining_commits = commits[(commit_idx+1)..-1]

          puts "Looks like you have a conflict to resolve!"
          exit
        end
      end

      repo.references.update(repo.branches["master"], repo.head.target_id)
      repo.head = "refs/heads/master"

      git_to_litdiff!

      @git.remaining_commits = nil

      puts "Success!"
    end
  end
end
