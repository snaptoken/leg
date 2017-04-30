class Snaptoken::Commands::Help < Snaptoken::Commands::BaseCommand
  def self.name
    "help"
  end

  def self.summary
    "Print out command list, or get help on a specific command"
  end

  def self.usage
    "[command]"
  end

  def setopts!(o)
  end

  def run
    if @args.empty?
      puts "Usage: leg <command> [args...]"
      puts
      puts "Commands:"
      Snaptoken::Commands::LIST.each do |cmd|
        puts "  #{cmd.name} #{cmd.usage}"
        puts "      #{cmd.summary}"
      end
    elsif cmd = Snaptoken::Commands::LIST.find { |cmd| cmd.name == @args.first }
      cmd.new(["--help"], @config)
    else
      puts "There is no '#{@args.first}' command."
    end
  end
end

