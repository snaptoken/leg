module Leg
  module Commands
    class Step < BaseCommand
      def self.name
        "step"
      end

      def self.summary
        "Select a step for editing."
      end

      def self.usage
        "<step-number>"
      end

      def setopts!(o)
      end

      def run
        needs! :config, :repo

        step_number = @args.first.to_i

        unless @git.checkout!(@args.first.to_i)
          output "Error: Step not found.\n"
          return false
        end
      end
    end
  end
end
