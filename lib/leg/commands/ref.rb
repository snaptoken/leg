class Leg::Commands::Ref < Leg::Commands::BaseCommand
  def self.name
    "ref"
  end

  def self.summary
    "Convert a step number or name to a git commit reference"
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
        step_num = (idx + 1).to_s
        step_name = commit.message.lines.first.strip

        if (is_num && ref == step_num) || (!is_num && ref == step_name)
          puts commit.oid
          exit
        end
      end

      puts "Error: reference not found"
      exit!
    end
  end
end

