class Leg::Commands::Commit < Leg::Commands::BaseCommand
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

    if @git.commit!
      git_to_litdiff!
      puts "Success!"
    else
      puts "Looks like you've got a conflict to resolve!"
    end
  end
end
