module Leg
  module Commands
    class Help < BaseCommand
      def self.name
        "help"
      end

      def self.summary
        "Print out list of commands, or get help\n" +
        "on a specific command."
      end

      def self.usage
        "[<command>]"
      end

      def setopts!(o)
      end

      def run
        if @args.empty?
          puts "<< Hello! I am leg, version #{Leg::VERSION} >>"
          puts
          puts "Usage: leg <command> [args...]"
          puts
          puts "Commands:"
          Leg::Commands::LIST.each do |cmd|
            puts "  #{cmd.name} #{cmd.usage}"
            cmd.summary.split("\n").each do |line|
              puts "      #{line}"
            end
          end
          puts
          puts "For more help on a specific command, run `leg help <command>`."
        elsif cmd = Leg::Commands::LIST.find { |cmd| cmd.name == @args.first }
          cmd.new(["--help"], @tutorial)
        else
          puts "There is no '#{@args.first}' command."
        end
      end
    end
  end
end
