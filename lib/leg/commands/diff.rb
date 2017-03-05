class Leg::Commands::Diff < Leg::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Display a diff between two versions of a file"
  end

  def run
    needs! :config

    step = @args.first || latest_step
    step_idx = steps.index(step)
    prev_step = steps[step_idx - 1]

    FileUtils.cd(@config[:path]) do
      shell_command("git diff --no-index #{prev_step} #{step}", exec: true)
    end
  end
end

