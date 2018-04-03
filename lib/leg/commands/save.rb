module Leg
  module Commands
    class Save < BaseCommand
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
          output "Success!\n"
        else
          output "Looks like you've got a conflict to resolve!\n"
        end
      end
    end
  end
end
