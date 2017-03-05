class Leg::Commands::Next < Leg::Commands::BaseCommand
  def self.name
    "next"
  end

  def self.summary
    "Create a new step that is a copy of the latest step"
  end

  def run
    needs! :config

    latest_step = steps.last
    next_step = (latest_step.to_i + 1).to_s

    FileUtils.cd(@config[:path]) do
      shell_command("cp -r #{latest_step} #{next_step}")
    end
  end
end

