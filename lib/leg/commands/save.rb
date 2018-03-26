class Leg::Commands::Save < Leg::Commands::BaseCommand
  def self.name
    "save"
  end

  def self.summary
    "Save changes to doc/."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    if @git.rebase_remaining!
      git_to_litdiff!
      puts "Success!"
    else
      puts "Looks like you've got a conflict to resolve!"
    end
  end
end
