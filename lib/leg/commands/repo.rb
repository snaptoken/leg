class Leg::Commands::Repo < Leg::Commands::BaseCommand
  def self.name
    "repo"
  end

  def self.summary
    "Convert step folders into a version controlled repository"
  end

  def run
    needs! :config

    FileUtils.cd(@config[:path])

    if File.exist?("repo")
      puts "Error: repo folder already exists!"
      exit!
    end

    if !File.exist?("steps")
      puts "Error: no steps folder"
      exit!
    end

    FileUtils.mkdir("repo")
    repo = Rugged::Repository.init_at("repo")

    steps.each do |step|
      index = repo.index
      index.read_tree(repo.head.target.tree) unless repo.empty?

      FileUtils.cd(step_path(step)) do
        Dir["**/*"].each do |path|
          unless File.directory?(path)
            oid = repo.write(File.read(path), :blob)
            index.add(path: path, oid: oid, mode: 0100644)
          end
        end
      end

      options = {}
      options[:tree] = index.write_tree(repo)
      options[:message] = step_name(step) || "-"
      options[:parents] = repo.empty? ? [] : [repo.head.target]
      options[:update_ref] = 'HEAD'

      Rugged::Commit.create(repo, options)
    end

    repo.checkout_head(strategy: :force)
  end
end

