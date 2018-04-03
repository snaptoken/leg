module Leg
  module Commands
    class Status < BaseCommand
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
            output "Nothing to report.\n"
          else
            output "Step #{state.step_number} checked out into step/.\n"
          end
        when :commit
          if state.args[1]
            output "Amended step #{state.step_number}. "
          end
          if state.args[0] > 0
            output "Added #{state.args[0]} step#{'s' if state.args[0] != 1} after step #{state.step_number}."
          end
          output "\n"
        else
          raise "unknown operation"
        end

        if state.conflict
          output "\n"
          output "Currently in a merge conflict. Resolve the conflict in step/ and\n"
          output "run `leg resolve` to continue.\n"
        elsif !state.operation.nil?
          output "\n"
          output "The above change(s) have not been saved yet. Run `leg save` to\n"
          output "save to the doc/ folder.\n"
        end
      end
    end
  end
end
