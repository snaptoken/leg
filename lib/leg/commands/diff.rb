class Leg::Commands::Diff < Leg::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Convert repo into a single file containing diffs for each step"
  end

  def run
    needs! :config

    if !File.exist?(File.join(@config[:path], "repo"))
      puts "Error: repo folder doesn't exist!"
      exit!
    end

    FileUtils.cd(File.join(@config[:path], "repo")) do
      patches = `git format-patch --stdout -p --no-signature --root master`
      File.open("../steps.diff", "w") do |f|
        step_num = 1
        patches.each_line do |line|
          if line =~ /^(From|Date|index)/
            # skip
          elsif line =~ /^Subject: \[[^\]]*\](.*)$/
            f << "\n" unless step_num == 1
            step_name = $1.strip
            if step_name =~ /^\w+(-\w+)*$/
              f << "~~~ step: #{step_name}\n"
            else
              f << "~~~ step\n"
            end
            step_num += 1
          elsif line.chomp.length > 0
            f << line
          end
        end
      end
    end
  end
end

