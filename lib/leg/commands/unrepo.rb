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

    repo = Rugged::Repository.new("repo")

    tag_names = {}
    repo.tags.each do |tag|
      if tag.name !~ /\A\d+(\.\d+)*\z/
        tag_names[tag.target.oid] = tag.name
      end
    end

    walker = Rugged::Walker.new(repo)
    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
    walker.push(repo.branches.find { |b| b.name == "master" }.target)
    walker.each.with_index do |commit, idx|
      step = (idx + 1).to_s
      step_name = step
      if tag_name = tag_names[commit.oid]
        step_name += "-#{tag_name}"
      end

      step_path = File.join(@config[:path], step_name)

      repo.checkout(commit.oid, strategy: :force, target_directory: step_path)
    end

    FileUtils.rm_r("repo")
  end
end

