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
      puts "Error: A repo already exists!"
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
      options[:message] = step
      options[:parents] = repo.empty? ? [] : [repo.head.target]
      options[:update_ref] = 'HEAD'

      commit_oid = Rugged::Commit.create(repo, options)

      tags = []
      if idx = step.index('-')
        tags << step[0...idx]
        tags << step[(idx+1)..-1]
      else
        tags << step
      end

      tags.each do |tag|
        repo.references.create("refs/tags/#{tag}", commit_oid)
      end
    end

    repo.checkout_head(strategy: :force)

    File.write("repo/.git/hooks/post-commit", POST_COMMIT_HOOK)
    File.write("repo/.git/hooks/prepare-commit-msg", PREPARE_COMMIT_MSG_HOOK)
    FileUtils.chmod(0755, "repo/.git/hooks/post-commit")
    FileUtils.chmod(0755, "repo/.git/hooks/prepare-commit-msg")

    FileUtils.rm_r(steps)
  end

  POST_COMMIT_HOOK = <<~'EOF'
    #!/usr/bin/env ruby

    require 'rugged'

    repo = Rugged::Repository.discover
    commit = repo.head.target
    parts = commit.message.lines.first.strip.split('-').reject(&:empty?)
    tags = [parts.shift]
    tags << parts.join('-') unless parts.empty?

    tags.each do |tag|
      repo.references.create("refs/tags/#{tag}", commit.oid)
    end
  EOF

  PREPARE_COMMIT_MSG_HOOK = <<~'EOF'
    #!/usr/bin/env ruby

    require 'rugged'

    repo = Rugged::Repository.discover
    last_commit = repo.head.target
    step_num = nil
    repo.tags.each do |tag|
      if tag.name =~ /\A\d+(\.\d+)*\z/ && tag.target.oid == last_commit.oid
        step_num = tag.name
        break
      end
    end

    if step_num
      step_num = step_num.split('.')
      step_num[-1] = (step_num[-1].to_i + 1).to_s
      step_num = step_num.join('.')

      msg = File.read(ARGV[0])
      msg = "#{step_num}-#{msg}"
      File.write(ARGV[0], msg)
    end
  EOF
end

