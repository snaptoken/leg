class Leg::Commands::Status < Leg::Commands::BaseCommand
  def self.name
    "status"
  end

  def self.summary
    "Show unsaved changes and the state of the step/ folder."
  end

  def self.usage
    ""
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    state = @git.state
    case state.operation
    when nil
      if state.step_number.nil?
        puts "Nothing to report."
      else
        puts "Step #{state.step_number} checked out into step/."
      end
    when :commit
      if state.args[1]
        print "Amended step #{state.step_number}. "
      end
      if state.args[0] > 0
        print "Added #{state.args[0]} step#{'s' if state.args[0] != 1} after step #{state.step_number}."
      end
      puts
    else
      raise "unknown operation"
    end

    if state.conflict
      puts
      puts "Currently in a merge conflict. Resolve the conflict in step/ and"
      puts "run `leg resolve` to continue."
    elsif !state.operation.nil?
      puts
      puts "The above change(s) have not been saved yet. Run `leg save` to"
      puts "save to the doc/ folder."
    end
  end
end
