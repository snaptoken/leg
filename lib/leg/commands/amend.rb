class Leg::Commands::Amend < Leg::Commands::BaseCommand
  def self.name
    "amend"
  end

  def self.summary
    "Modify a step."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    if @git.commit!(amend: true)
      git_to_litdiff!
      puts "Success!"
    else
      puts "Looks like you've got a conflict to resolve!"
    end
  end
end
