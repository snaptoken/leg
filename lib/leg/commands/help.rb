class Leg::Commands::Help < Leg::Commands::BaseCommand
  def self.name
    "help"
  end

  def self.summary
    "Print out this help"
  end

  def run
    puts "Usage: leg <command> [args...]"
    puts
    puts "Commands:"
    Leg::Commands::LIST.each do |cmd|
      puts "  #{cmd.name}"
      puts "      #{cmd.summary}"
    end
  end
end

