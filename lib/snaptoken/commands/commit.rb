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

    repo = Rugged::Repository::new(File.join(@tutorial.config[:path], ".leg/repo"))
    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    master_commit = repo.branches["master"].target
    if master_commit.oid != repo.head.target_id
      walker.push(master_commit)
      walker.hide(repo.head.target)
      remaining_commits = walker.to_a
    else
      remaining_commits = []
    end

    # 1. Copy `step/*` to `.leg/repo/*`
    @tutorial.copy_step_to_repo!

    FileUtils.cd(File.join(@tutorial.config[:path], ".leg/repo")) do
      # 2. Run `git add -A`
      `git add -A`

      # 3. Run `git commit`
      `git commit -m"TODO: let user specify commit message"`

      # 4. Run `git cherry-pick` on each remaining step, pausing for conflicts
      remaining_commits.each do |commit|
        # 4a. Walk over remaining commits on `master`

        # 4b. Run `git cherry-pick` on the current commit hash
        `git cherry-pick #{commit.oid}`

          # 4b(i). If that resulted in a conflict, copy `.leg/repo/*` to `step/*` and
          #        save the commit hash of the step to continue with after the conflict
          #        is resolved, and also report to the user which files have conflicts.
          #        Exit the program, and resume when `leg resolve` is run.

          # 4b(ii). Copy `step/*` to `.leg/repo/*`, run `git add -A` and `git commit`
          #         (or however you resolve a cherry-pick conflict...)
      end

      # 5. Update `master` branch to the new rebased branch
      repo.references.update(repo.branches["master"], repo.head.target_id)
      repo.head = repo.branches["master"]
    end
  end
end
