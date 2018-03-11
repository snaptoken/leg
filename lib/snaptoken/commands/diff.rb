class Snaptoken::Commands::Diff < Snaptoken::Commands::BaseCommand
  def self.name
    "diff"
  end

  def self.summary
    "Convert repo/ to diff/.\n" +
    "Doesn't overwrite diff/ unless forced."
  end

  def self.usage
    "[-f] [-q]"
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

    unless @opts[:force]
      if @tutorial.diff_modified? && @tutorial.repo_modified?
        puts "Warning: Both diff/ and repo/ have been modified since they were last synced."
        puts "Aborting. Rerun with '-f' option to force overwriting diff/."
        exit!
      elsif @tutorial.diff_modified?
        puts "Warning: diff/ has been modified since last sync."
        puts "Aborting. Rerun with '-f' option to force overwriting diff/."
        exit!
      end
    end

    @tutorial.load_from_repo do |step_num|
      print "\r\e[K[repo/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
    end
    puts unless @opts[:quiet]

    num_steps = @tutorial.num_steps
    @tutorial.save_to_diff do |step_num|
      print "\r\e[K[Tutorial -> diff/] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
    end
    puts unless @opts[:quiet]

    FileUtils.touch(File.join(@tutorial.config[:path], ".last_synced"))
  end
end
