module Leg
  module Commands
    class BaseCommand
      attr_reader :config

      def initialize(args, config)
        @args = args
        @config = config
        @git = Leg::Representations::Git.new(@config)
        @litdiff = Leg::Representations::Litdiff.new(@config)
        parseopts!
      end

      def self.name; raise NotImplementedError; end
      def self.summary; raise NotImplementedError; end
      def setopts!(o); raise NotImplementedError; end
      def run; raise NotImplementedError; end

      def self.inherited(subclass)
        Leg::Commands::LIST << subclass
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
            if @config.nil?
              puts "Error: You are not in a leg working directory."
              exit 1
            end
          when :repo
            if @litdiff.modified? and @git.modified?
              puts "Error: doc/ and .leg/repo have diverged!"
              exit 1
            elsif @litdiff.modified? or !@git.exists?
              litdiff_to_git!
            end
          end
        end
      end

      def git_to_litdiff!
        tutorial = @git.load! do |step_num|
          print "\r\e[K[repo/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
        end
        puts unless @opts[:quiet]

        num_steps = tutorial.num_steps
        @litdiff.save!(tutorial) do |step_num|
          print "\r\e[K[Tutorial -> doc/] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
        end
        puts unless @opts[:quiet]

        @config.synced!
      end

      def litdiff_to_git!
        tutorial = @litdiff.load! do |step_num|
          print "\r\e[K[doc/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
        end
        puts unless @opts[:quiet]

        num_steps = tutorial.num_steps
        @git.save!(tutorial) do |step_num|
          print "\r\e[K[Tutorial -> repo/] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
        end
        puts unless @opts[:quiet]

        @config.synced!
      end
    end
  end
end
