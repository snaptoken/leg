class Leg::Commands::Undiff < Leg::Commands::BaseCommand
  def self.name
    "undiff"
  end

  def self.summary
    "Conver steps.diff to step folders"
  end

  def run
    needs! :config

    FileUtils.cd(@config[:path]) do
      if !File.exist?("steps.diff")
        puts "Error: steps.diff doesn't exist!"
        exit!
      end

      if File.exist?("steps")
        puts "Error: steps folder already exists!"
        exit!
      end

      FileUtils.mkdir("steps")
      FileUtils.cd("steps") do
        File.open("../steps.diff", "r") do |f|
          step_num = 0
          step_dir = nil
          prev_dir = nil
          cur_diff = nil
          while line = f.gets
            if line =~ /^~~~ step(: \w+(-\w+)*)?$/
              if cur_diff
                apply_diff(step_dir, cur_diff)
                cur_diff = nil
              end

              step_num += 1
              step_dir = step_num.to_s
              step_dir += "-#{$1[2..-1]}" if $1
              if step_num == 1
                FileUtils.mkdir(step_dir)
              else
                FileUtils.cp_r(prev_dir, step_dir)
              end
              prev_dir = step_dir
            elsif line =~ /^diff --git/
              apply_diff(step_dir, cur_diff) if cur_diff
              cur_diff = line
            elsif cur_diff
              cur_diff << line
            end
          end
          apply_diff(step_dir, cur_diff) if cur_diff
        end
      end
    end
  end

  private

  def apply_diff(dir, diff)
    stdin = IO.popen("git --git-dir= apply --directory=#{dir} -", "w")
    stdin.write diff
    stdin.close
  end
end

