class Snaptoken::Commands::Unrepo < Snaptoken::Commands::BaseCommand
  def self.name
    "unrepo"
  end

  def self.summary
    "Convert repo/ folder into steps/ folder"
  end

  def self.usage
    "[options]"
  end

  def setopts!(o)
    o.on("-f", "--force", "Overwrite steps/ folder") do |f|
      @opts[:force] = f
    end
  end

  def run
    needs! :config, :repo

    FileUtils.cd(@config[:path]) do
      if @opts[:force]
        FileUtils.rm_rf("steps")
      else
        needs! not: :steps_folder
      end

      FileUtils.mkdir("steps")

      repo = Rugged::Repository.new("repo")

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)
      walker.each.with_index do |commit, idx|
        break if commit.message.lines.first.strip == "-"

        step = Snaptoken::Step.from_commit_msg(idx + 1, commit.message.lines.first.strip)

        repo.checkout(commit.oid, strategy: :force,
                                  target_directory: step_path(step))
      end
    end
  end
end

