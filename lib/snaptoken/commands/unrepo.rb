class Snaptoken::Commands::Unrepo < Snaptoken::Commands::BaseCommand
  def self.name
    "unrepo"
  end

  def self.summary
    "Convert repository into steps folder"
  end

  def run
    needs! :config, :repo, not: :steps_folder

    FileUtils.cd(@config[:path]) do
      FileUtils.mkdir("steps")

      repo = Rugged::Repository.new("repo")

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)
      walker.each.with_index do |commit, idx|
        step_num = (idx + 1).to_s
        step_name = commit.message.lines.first.strip

        if step_name.empty?
          step = step_num
        else
          step = "#{step_num}-#{step_name}"
        end

        repo.checkout(commit.oid, strategy: :force,
                                  target_directory: step_path(step))
      end
    end
  end
end

