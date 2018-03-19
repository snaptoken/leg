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

  def needs!(*whats)
    whats.each do |what|
      case what
      when :config
        if @tutorial.nil?
          puts "Error: You are not in a leg working directory."
          exit 1
        end
      when :repo
        if @tutorial.diff_modified? and @tutorial.repo_modified?
          puts "Error: doc/ and .leg/repo have diverged!"
          exit 1
        elsif @tutorial.diff_modified? or @tutorial.repo_modified_at.nil?
          @tutorial.load_from_diff do |step_num|
            print "\r\e[K[doc/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
          end
          puts unless @opts[:quiet]

          num_steps = @tutorial.num_steps
          @tutorial.save_to_repo do |step_num|
            print "\r\e[K[Tutorial -> repo/] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
          end
          puts unless @opts[:quiet]

          FileUtils.touch(File.join(@tutorial.config[:path], ".leg/last_synced"))
        end
      end
    end
  end
end

