module Leg
  module Commands
    class Resolve < BaseCommand
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
          output "Success!\n"
        else
          output "Looks like you've got a conflict to resolve!\n"
        end
      end
    end
  end
end
