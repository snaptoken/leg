module Leg
  module Commands
    class Amend < BaseCommand
      def self.name
        "amend"
      end

      def self.summary
        "Modify a step."
      end

      def self.usage
         "[-s]"
      end

      def setopts!(o)
        o.on("-s", "--stay", "Don't resolve rest of steps yet") do |s|
          @opts[:stay] = s
        end
      end

      def run
        needs! :config, :repo

        if @git.commit!(amend: true, no_rebase: @opts[:stay])
          unless @opts[:stay]
            git_to_litdiff!
            output "Success!\n"
          end
        else
          output "Looks like you've got a conflict to resolve!\n"
        end
      end
    end
  end
end
