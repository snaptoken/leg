class Snaptoken::Commands::Repo < Snaptoken::Commands::BaseCommand
  def self.name
    "repo"
  end

  def self.summary
    "Convert steps folder into a version controlled repository"
  end

  def run
    needs! :config, :steps_folder, :steps, not: :repo

    FileUtils.cd(@config[:path])

    FileUtils.mkdir("repo")
    repo = Rugged::Repository.init_at("repo")

    steps.each do |step|
      commit_oid = add_commit(repo, step, step_path(step))

      if step.name
        repo.references.create("refs/tags/#{step.name}", commit_oid)
      end
    end

    if Dir.exist? "repo-extra"
      add_commit(repo, nil, [step_path(latest_step), "repo-extra"])
    end

    repo.checkout_head(strategy: :force)
  end

  private

  def add_commit(repo, step, add_paths)
    index = repo.index
    index.read_tree(repo.head.target.tree) unless repo.empty?

    Array(add_paths).each do |add_path|
      FileUtils.cd(add_path) do
        Dir["**/*"].each do |path|
          unless File.directory?(path)
            oid = repo.write(File.read(path), :blob)
            index.add(path: path, oid: oid, mode: 0100644)
          end
        end
      end
    end

    options = {}
    options[:tree] = index.write_tree(repo)
    options[:message] = step ? step.commit_msg : "-"
    options[:parents] = repo.empty? ? [] : [repo.head.target]
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
  end
end

