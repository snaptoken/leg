module Leg
  module Commands
    class Commit < BaseCommand
      def self.name
        "commit"
      end

      def self.summary
        "Append or insert a new step."
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

        if @git.commit!(no_rebase: @opts[:stay])
          unless @opts[:stay]
            git_to_litdiff!
            puts "Success!"
          end
        else
          puts "Looks like you've got a conflict to resolve!"
        end
      end
    end
  end
end
