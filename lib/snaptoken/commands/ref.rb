class Snaptoken::Commands::Ref < Snaptoken::Commands::BaseCommand
  def self.name
    "ref"
  end

  def self.summary
    "Get the commit hash in repo/ for a step\n" +
    "name or step number. `leg <step-number>`\n" +
    "can be used as a shortcut for\n" +
    "`leg ref <step-number>`."
  end

  def self.usage
    "[<step-name> | <step-number>]"
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    ref = @args.first
    is_num = (ref =~ /\A\d+\z/)

    FileUtils.cd(@config[:path]) do
      repo = Rugged::Repository.new("repo")

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)
      walker.each.with_index do |commit, idx|
        step = Snaptoken::Step.from_commit_msg(idx + 1, commit.message.lines.first.strip)

        if (is_num && ref.to_i == step.number) || (!is_num && ref == step.name)
          puts commit.oid
          exit
        end
      end

      puts "Error: reference not found"
      exit!
    end
  end
end

