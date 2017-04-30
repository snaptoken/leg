class Snaptoken::Commands::Repo < Snaptoken::Commands::BaseCommand
  def self.name
    "repo"
  end

  def self.summary
    "Convert steps/ to repo/. Doesn't overwrite\n" +
    "repo/ unless forced."
  end

  def self.usage
    "[-f] [-q]"
  end

  def setopts!(o)
    o.on("-f", "--force", "Overwrite repo/ folder") do |f|
      @opts[:force] = f
    end

    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config, :steps_folder, :steps

    FileUtils.cd(@config[:path])

    if @opts[:force]
      FileUtils.rm_rf("repo")
    else
      needs! not: :repo
    end

    FileUtils.mkdir("repo")
    repo = Rugged::Repository.init_at("repo")

    steps.each do |step|
      print "\r\e[K[steps/ -> repo/] #{step.folder_name}" unless @opts[:quiet]
      commit_oid = add_commit(repo, step, step_path(step))

      if step.name
        repo.references.create("refs/tags/#{step.name}", commit_oid)
      end
    end
    print "\n" unless @opts[:quiet]

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
    if @config[:repo_author]
      options[:author] = {
        name: @config[:repo_author][:name],
        email: @config[:repo_author][:email],
        time: Time.now
      }
      options[:committer] = options[:author]
    end
    options[:message] = step ? step.commit_msg : "-"
    options[:parents] = repo.empty? ? [] : [repo.head.target]
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
  end
end

