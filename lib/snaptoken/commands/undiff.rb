class Snaptoken::Commands::Undiff < Snaptoken::Commands::BaseCommand
  def self.name
    "undiff"
  end

  def self.summary
    "Convert steps.diff to steps folder"
  end

  def run
    needs! :config, :diff, not: :steps_folder

    FileUtils.cd(@config[:path]) do
      FileUtils.mkdir("steps")
      FileUtils.cd("steps") do
        File.open("../steps.diff", "r") do |f|
          step_num = 0
          step = Snaptoken::Step.new(0, nil, [])
          prev_step = nil
          cur_diff = nil
          while line = f.gets
            if line =~ /^~~~ step: ([\s\w-]+)$/
              if cur_diff
                apply_diff(step, cur_diff)
                cur_diff = nil
              end

              prev_step = step
              step = Snaptoken::Step.from_commit_msg(prev_step.number + 1, $1)

              if step.number == 1
                FileUtils.mkdir(step.folder_name)
              else
                FileUtils.cp_r(prev_step.folder_name, step.folder_name)
              end
            elsif line =~ /^diff --git/
              apply_diff(step, cur_diff) if cur_diff
              cur_diff = line
            elsif cur_diff
              cur_diff << line
            end
          end
          apply_diff(step, cur_diff) if cur_diff
        end
      end
    end
  end

  private

  def apply_diff(step, diff)
    stdin = IO.popen("git --git-dir= apply \"--directory=#{step.folder_name}\" -", "w")
    stdin.write diff
    stdin.close
  end
end

