class Snaptoken::Commands::Sync < Snaptoken::Commands::BaseCommand
  def self.name
    "sync"
  end

  def self.summary
    "Sync repo/, steps/, and steps.diff using\n" +
    "one of them as the source. The <source> can\n" +
    "be 'repo', 'steps', or 'diff'. The :sync\n" +
    "option in leg.yml sets the default source.\n" +
    "If only one possible source exists, then that\n" +
    "is the default source."
  end

  def self.usage
    "[-q] [<source>]"
  end

  def setopts!(o)
    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config

    source = nil
    if !@args.empty?
      source = @args.first
    else
      FileUtils.cd(@config[:path])
      repo_exists = File.exist?("repo")
      steps_exists = File.exist?("steps")
      diff_exists = File.exist?("steps.diff")

      if !repo_exists && !steps_exists && !diff_exists
        puts "Error: nothing to sync from."
        exit
      end

      if repo_exists && !steps_exists && !diff_exists
        source = "repo"
      elsif steps_exists && !repo_exists && !diff_exists
        source = "steps"
      elsif diff_exists && !repo_exists && !steps_exists
        source = "diff"
      else
        needs! :config_sync
        source = @config[:sync]
      end
    end

    if ! %w(repo steps diff).include?(source)
      puts "Error: sync source must be 'repo', 'steps', or 'diff'."
      exit
    end

    needs! source.to_sym

    args = @opts[:quiet] ? ["--quiet"] : []
    case source.to_sym
    when :repo
      Snaptoken::Commands::Diff.new(args + [], @config).run
      Snaptoken::Commands::Undiff.new(args + ["--force"], @config).run
    when :steps
      Snaptoken::Commands::Repo.new(args + ["--force"], @config).run
      Snaptoken::Commands::Diff.new(args + [], @config).run
    when :diff
      Snaptoken::Commands::Undiff.new(args + ["--force"], @config).run
      Snaptoken::Commands::Repo.new(args + ["--force"], @config).run
    end
  end
end

