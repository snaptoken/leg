class Leg::Commands::Step < Leg::Commands::BaseCommand
  def self.name
    "step"
  end

  def self.summary
    "Select a step for editing."
  end

  def self.usage
    "<step-number>"
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    step_number = @args.first.to_i

    FileUtils.cd(@git.repo_path) do
      @git.each_step do |cur_step, commit|
        if cur_step == step_number
          `git checkout #{commit.oid}`
          @git.copy_repo_to_step!
          exit
        end
      end

      puts "Error: Step not found."
      exit 1
    end
  end
end
