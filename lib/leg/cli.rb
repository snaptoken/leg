module Leg
  class CLI
    def initialize(options = {})
      @options = options

      initial_dir = FileUtils.pwd

      @config = nil
      last_dir = nil
      while FileUtils.pwd != last_dir
        if File.exist?("leg.yml")
          @config = Leg::Config.new(FileUtils.pwd)
          @config.load!
          break
        end

        last_dir = FileUtils.pwd
        FileUtils.cd("..")
      end

      FileUtils.cd(initial_dir)
    end

    def run(args)
      args = ["help"] if args.empty?
      cmd_name = args.shift.downcase

      if cmd_name =~ /\A\d+\z/
        args.unshift(cmd_name)
        cmd_name = "step"
      end

      if cmd = Leg::Commands::LIST.find { |cmd| cmd.name == cmd_name }
        command = cmd.new(args, @config)
        command.opts[:quiet] = true if @options[:force_quiet]
        command.run
      else
        puts "There is no '#{cmd_name}' command. Run `leg help` for help."
      end
    end
  end
end
