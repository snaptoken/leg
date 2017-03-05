class Leg::Commands::Ls < Leg::Commands::BaseCommand
  def self.name
    "ls"
  end

  def self.summary
    "List step directories in order"
  end

  def run
    needs! :config

    steps.each { |s| puts s }
  end
end

