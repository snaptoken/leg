class Snaptoken::Commands::Undiff < Snaptoken::Commands::BaseCommand
  def self.name
    "undiff"
  end

  def self.summary
    "Convert steps.diff to repo/. Doesn't\n" +
    "overwrite repo/ unless forced."
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
    needs! :config, :diff

    FileUtils.cd(@config[:path]) do
      if @opts[:force]
        FileUtils.rm_rf("repo")
      else
        needs! not: :repo
      end

      FileUtils.mkdir("repo")
      repo = Rugged::Repository.init_at("repo")

      FileUtils.cd("repo") do
        step_num = 0
        Dir["../*.leg"].sort.each do |leg_path|
          chapter_name = File.basename(leg_path).sub(/\.leg$/, "")
          add_step(repo, step_num, "~~~ #{chapter_name}", nil)
          File.open(leg_path, "r") do |f|
            cur_message = nil
            cur_diff = nil
            while line = f.gets
              if line.strip == "~~~"
                if cur_message || cur_diff
                  add_step(repo, step_num, cur_message, cur_diff)
                  cur_message = nil
                  cur_diff = nil
                  step_num += 1
                end
                print "\r\e[K[litdiff -> repo/] Step #{step_num}" unless @opts[:quiet]
              elsif cur_diff
                cur_diff << line
              elsif line =~ /^diff --git/
                cur_diff = line
              else
                cur_message ||= ""
                cur_message << line
              end
            end
            if cur_message || cur_diff
              add_step(repo, step_num, cur_message, cur_diff)
              step_num += 1
            end
          end
        end
        print "\n" unless @opts[:quiet]

        if Dir.exist? "../repo-extra"
          FileUtils.cp_r("../repo-extra/.", ".")
          add_commit(repo, step_num, "-")
        end

        repo.checkout_head(strategy: :force)
      end
    end
  end

  private

  def add_step(repo, step_num, message, diff)
    message ||= ""
    message.strip!
    message = "Step #{step_num}" if message.empty?

    apply_diff(diff) if diff
    commit_oid = add_commit(repo, step_num, message)
    if diff and summary = message.lines.first
      tag_name = summary.downcase.gsub(/\W+/, '-').gsub(/-+/, '-').sub(/^-/, '').sub(/-$/, '')
      repo.references.create("refs/tags/#{tag_name}", commit_oid)
    end
  end

  def apply_diff(diff)
    stdin = IO.popen("git apply -", "w")
    stdin.write diff
    stdin.close
  end

  def add_commit(repo, step_num, message)
    index = repo.index
    index.read_tree(repo.head.target.tree) unless repo.empty?

    File.write(".dummyleg", step_num)

    (Dir["**/*"] + [".dummyleg"]).each do |path|
      unless File.directory?(path)
        oid = repo.write(File.read(path), :blob)
        index.add(path: path, oid: oid, mode: 0100644)
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
    options[:message] = message
    options[:parents] = repo.empty? ? [] : [repo.head.target]
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
  end
end

