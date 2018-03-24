class Snaptoken::Commands::Amend < Snaptoken::Commands::BaseCommand
  def self.name
    "amend"
  end

  def self.summary
    "Modify a step."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    repo = Rugged::Repository::new(File.join(@tutorial.config[:path], ".leg/repo"))
    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    master_commit = repo.branches["master"].target
    if master_commit.oid != repo.head.target_id
      walker.push(master_commit)
      walker.hide(repo.head.target)
      remaining_commits = walker.to_a.map(&:oid)
    else
      remaining_commits = []
    end

    @tutorial.copy_step_to_repo!

    FileUtils.cd(File.join(@tutorial.config[:path], ".leg/repo")) do
      `git add -A`
      `git commit --amend -m"TODO: let user specify commit message"`

      remaining_commits.each.with_index do |commit, commit_idx|
        `git cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits #{commit}`

        if not $?.success?
          @tutorial.copy_repo_to_step!

          File.write(
            File.join(@tutorial.config[:path], ".leg/remaining_commits"),
            remaining_commits[(commit_idx+1)..-1].join("\n")
          )

          puts "Looks like you have a conflict to resolve!"
          exit
        end
      end

      repo.references.update(repo.branches["master"], repo.head.target_id)
      repo.head = "refs/heads/master"

      @tutorial.load_from_repo.save_to_diff
      FileUtils.touch(File.join(@tutorial.config[:path], ".leg/last_synced"))

      FileUtils.rm_f("../remaining_commits")

      puts "Success!"
    end
  end
end
