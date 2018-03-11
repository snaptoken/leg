class Snaptoken::Commands::Ref < Snaptoken::Commands::BaseCommand
  def self.name
    "ref"
  end

  def self.summary
    "Get the commit hash in repo/ for a step\n" +
    "number. `leg <step-number>` can be used\n" +
    "as a shortcut for `leg ref <step-number>`."
  end

  def self.usage
    "<step-number>"
  end

  def setopts!(o)
  end

  def run
    needs! :config, :repo

    step_number = @args.first.to_i

    FileUtils.cd(@tutorial.config[:path]) do
      repo = Rugged::Repository.new("repo")
      empty_tree = Rugged::Tree.empty(repo)

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)

      cur_step = 1
      walker.each do |commit|
        next if commit.message.strip == "-"
        last_commit = commit.parents.first
        diff = (last_commit || empty_tree).diff(commit)
        patches = diff.each_patch.reject { |p| p.delta.new_file[:path] == ".dummyleg" }
        next if patches.empty?

        if step_number == cur_step
          puts commit.oid
          exit
        end

        cur_step += 1
      end

      puts "Error: step not found"
      exit!
    end
  end
end

