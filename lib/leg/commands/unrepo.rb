class Leg::Commands::Unrepo < Leg::Commands::BaseCommand
  def self.name
    "unrepo"
  end

  def self.summary
    "Convert repository into step folders"
  end

  def run
    needs! :config

    FileUtils.cd(@config[:path])

    if !File.exist?("repo")
      puts "Error: repo folder doesn't exist!"
      exit!
    end

    if File.exist?("steps")
      puts "Error: steps folder already exists!"
      exit!
    end

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

