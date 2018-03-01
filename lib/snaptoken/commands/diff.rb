class Snaptoken::Commands::Diff < Snaptoken::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Convert repo/ to diff/.\n" +
    "Doesn't overwrite diff/ unless forced."
  end

  def self.usage
    "[-f ] [-q]"
  end

  def setopts!(o)
    o.on("-f", "--force", "Overwrite diff/ folder") do |f|
      @opts[:force] = f
    end

    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config, :repo
    needs! not: :diff unless @opts[:force]

    repo_path = File.join(@config[:path], "repo")
    diff_path = File.join(@config[:path], "diff")

    tutorial = Snaptoken::Tutorial.from_repo(repo_path)
    tutorial.save_to_diff(diff_path)
  end
end

