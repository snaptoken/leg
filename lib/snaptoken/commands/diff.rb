class Snaptoken::Commands::Diff < Snaptoken::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Convert repo/ to steps.diff."
  end

  def self.usage
    "[-q]"
  end

  def setopts!(o)
    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config, :repo

    FileUtils.cd(File.join(@config[:path], "repo")) do
      patches = `git format-patch --stdout -p --no-signature --histogram --root master`
      File.open("../steps.diff", "w") do |f|
        step_num = 1
        patches.each_line do |line|
          if line =~ /^(From|Date|index)/
            # skip
          elsif line =~ /^Subject: \[[^\]]*\](.*)$/
            break if $1.strip == "-"
            f << "\n" unless step_num == 1
            step = Snaptoken::Step.from_commit_msg(step_num, $1.strip)
            print "\r\e[K[repo/ -> steps.diff] #{step.folder_name}" unless @opts[:quiet]
            f << "~~~ step: #{step.commit_msg}\n"
            step_num += 1
          elsif line.chomp.length > 0
            f << line
          end
        end
        print "\n" unless @opts[:quiet]
      end
    end
  end
end

