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

    # 1. Copy `step/*` to `.leg/repo/*`
    @tutorial.copy_step_to_repo!

    FileUtils.cd(File.join(@tutorial.config[:path], ".leg/repo")) do
      # 2. Run `git add -A`
      `git add -A`

      # 3. Run `git commit`
      `git commit -m"TODO: let user specify commit message"`

      # 4. Run `git cherry-pick` on each remaining step, pausing for conflicts

        # 4a. Walk over remaining commits on `master`

        # 4b. Run `git cherry-pick` on the current commit hash

          # 4b(i). If that resulted in a conflict, copy `.leg/repo/*` to `step/*` and
          #        save the commit hash of the step to continue with after the conflict
          #        is resolved, and also report to the user which files have conflicts.
          #        Exit the program, and resume when `leg resolve` is run.

          # 4b(ii). Copy `step/*` to `.leg/repo/*`, run `git add -A` and `git commit`
          #         (or however you resolve a cherry-pick conflict...)

      # 5. Update `master` branch to the new rebased branch
    end
  end
end
