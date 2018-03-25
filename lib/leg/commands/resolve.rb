class Leg::Commands::Resolve < Leg::Commands::BaseCommand
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

    if @git.resolve!
      git_to_litdiff!
      puts "Success!"
    else
      puts "Looks like you've got a conflict to resolve!"
    end
  end
end
