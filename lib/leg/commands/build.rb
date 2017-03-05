class Leg::Commands::Build < Leg::Commands::BaseCommand
  def self.name
    "build"
  end

  def self.summary
    "Build a version (latest by default) of a project"
  end

  def run
    needs! :config
    needs! :config_build

    select_step(current_or_latest_step) do
      shell_command(@config[:build])
    end
  end
end

