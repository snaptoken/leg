class Snaptoken::Commands::BaseCommand
  attr_reader :config

  def initialize(args, tutorial)
    @args = args
    @tutorial = tutorial
    parseopts!
  end

  def self.name; raise NotImplementedError; end
  def self.summary; raise NotImplementedError; end
  def setopts!(o); raise NotImplementedError; end
  def run; raise NotImplementedError; end

  def self.inherited(subclass)
    Snaptoken::Commands::LIST << subclass
  end

  def parseopts!
    parser = OptionParser.new do |o|
      o.banner = "Usage: leg #{self.class.name} #{self.class.usage}"
      self.class.summary.split("\n").each do |line|
        o.separator "    #{line}"
      end
      o.separator ""
      o.separator "Options:"
      setopts!(o)
      o.on_tail("-h", "--help", "Show this message") do
        puts o
        exit
      end
    end
    @opts = {}
    parser.parse!(@args)
  rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
    puts "#{e.message}"
    puts
    parser.parse("--help")
  end

  ERROR_MSG = {
    config: {
      true: "You are not in a leg working directory.",
      false: "You are already in a leg working directory."
    },
    repo: {
      true: "There is no repo folder.",
      false: "There is already a repo folder."
    },
    diff: {
      true: "There is no diff folder.",
      false: "There is already a diff folder."
    },
    template: {
      true: "There is no template folder."
    },
    cached_diffs: {
      true: "There are no cached diffs."
    }
  }

  def needs!(*whats)
    options = whats.pop if whats.last.is_a? Hash
    options ||= {}

    yes = Array(whats).flatten.map { |w| [w, true] }
    no = Array(options[:not]).map { |w| [w, false] }

    (yes + no).each do |what, v|
      valid =
        case what
        when :config
          !!@tutorial
        when :repo
          File.exist?(File.join(@tutorial.path, "repo"))
        when :diff
          File.exist?(File.join(@tutorial.path, "diff"))
        when :template
          File.exist?(File.join(@tutorial.path, "template"))
        when :cached_diffs
          File.exist?(File.join(@tutorial.path, ".cached-diffs"))
        else
          raise NotImplementedError
        end

      if valid != v
        puts "Error: " + ERROR_MSG[what][v.to_s.to_sym]
        exit!
      end
    end
  end
end

