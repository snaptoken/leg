class Snaptoken::Commands::Sync < Snaptoken::Commands::BaseCommand
  def self.name
    "sync"
  end

  def self.summary
    "Sync repo/ and diff/, converting the\n" +
    "one that has been modified since last\n" +
    "sync to the other."
  end

  def self.usage
    "[-q]"
  end

  def setopts!(o)
    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config

    args = @opts[:quiet] ? ["--quiet"] : []

    if @tutorial.diff_modified? && @tutorial.repo_modified?
      puts "Warning: Both diff/ and repo/ have been modified since they were last synced."
      puts "Aborting. Run `leg diff -f` or `leg repo -f` to overwrite diff/ or repo/, respectively."
      exit!
    elsif @tutorial.diff_modified?
      Snaptoken::Commands::Repo.new(args + ["--force"], @tutorial).run
    elsif @tutorial.repo_modified?
      Snaptoken::Commands::Diff.new(args + ["--force"], @tutorial).run
    else
      puts "Already synced." unless @opts[:quiet]
    end
  end
end
