class Snaptoken::Commands::Undiff < Snaptoken::Commands::BaseCommand
  def self.name
    "undiff"
  end

  def self.summary
    "Convert diff/ to repo/.\n" +
    "Doesn't overwrite repo/ unless forced."
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
    needs! not: :repo unless @opts[:force]

    diff_path = File.join(@config[:path], "diff")
    repo_path = File.join(@config[:path], "repo")
    extra_path = File.join(@config[:path], "repo-extra")

    tutorial = Snaptoken::Tutorial.from_diff(diff_path)

    if Dir.exist? extra_path
      tutorial.save_to_repo(repo_path, extra_path: extra_path)
    else
      tutorial.save_to_repo(repo_path)
    end
  end
end
