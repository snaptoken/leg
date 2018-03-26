class Leg::Commands::Diff < Leg::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Compare last step with changes made in step/."
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
      system("git diff")
    end
  end
end
