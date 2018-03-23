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

    remaining_commits = File.read(File.join(@tutorial.config[:path], ".leg/remaining_commits"))
    remaining_commits = remaining_commits.lines.map(&:strip).reject(&:empty?)

    @tutorial.copy_step_to_repo!

    FileUtils.cd(File.join(@tutorial.config[:path], ".leg/repo")) do
      `git add -A`

      `git -c core.editor=true cherry-pick --allow-empty --allow-empty-message --keep-redundant-commits --continue`

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

      repo = Rugged::Repository::new(File.join(@tutorial.config[:path], ".leg/repo"))
      repo.references.update(repo.branches["master"], repo.head.target_id)
      repo.head = "refs/heads/master"

      @tutorial.load_from_repo.save_to_diff
      FileUtils.touch(File.join(@tutorial.config[:path], ".leg/last_synced"))

      FileUtils.rm_f("../remaining_commits")

      puts "Success!"
    end
  end
end
