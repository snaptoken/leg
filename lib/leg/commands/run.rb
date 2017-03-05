class Leg::Commands::Run < Leg::Commands::BaseCommand
  def self.name
    "run"
  end

  def self.summary
    "Build and run a version (latest by default) of the project"
  end

  def run
    needs! :config
    needs! :config_run

    select_step(current_or_latest_step) do
      shell_command(@config[:run], exec: true)
    end
  end
end

