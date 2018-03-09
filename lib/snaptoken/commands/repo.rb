class Snaptoken::Commands::Repo < Snaptoken::Commands::BaseCommand
  def self.name
    "repo"
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

    options = {}

    extra_path = File.join(@tutorial.path, "repo-extra")
    if Dir.exist? extra_path
      options[:extra_path] = extra_path
    end

    @tutorial.load_from_diff do |step_num|
      print "\r\e[K[diff/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
    end
    puts unless @opts[:quiet]

    num_steps = @tutorial.num_steps
    @tutorial.save_to_repo(options) do |step_num|
      print "\r\e[K[Tutorial -> repo/] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
    end
    puts unless @opts[:quiet]
  end
end
