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

    @tutorial.load_from_repo.save_to_diff
  end
end

