class Leg::Commands::Reset < Leg::Commands::BaseCommand
  def self.name
    "reset"
  end

  def self.summary
    "Abort any saves in progress and checkout the top-most step."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    @git.reset!
  end
end
