module Leg
  class CLI
    def initialize
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
        cmd.new(args, @config).run
      else
        puts "There is no '#{cmd_name}' command. Run `leg help` for help."
        1
      end
    end
  end
end
