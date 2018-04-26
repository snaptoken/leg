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
        o.on("-m", "--message MESSAGE", "Set the step summary to MESSAGE") do |m|
          @opts[:message] = m
        end
        o.on("-d", "--default-message", "Leave the step summary unchanged, or set it to a default if empty") do |d|
          @opts[:default_message] = d
        end
        o.on("-s", "--stay", "Don't resolve rest of steps yet") do |s|
          @opts[:stay] = s
        end
      end

      def run
        needs! :config, :repo

        commit_options = {
          amend: true,
          no_rebase: @opts[:stay],
          message: @opts[:message],
          use_default_message: @opts[:default_message]
        }

        if @git.commit!(commit_options)
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
