class Snaptoken::CLI
  CONFIG_FILE = "leg.yml"

  def initialize
    initial_dir = FileUtils.pwd

    last_dir = nil
    last_dir2 = nil
    while FileUtils.pwd != last_dir
      if File.exist?(CONFIG_FILE)
        @config = YAML.load(File.read(CONFIG_FILE))
        unless @config.is_a? Hash
          puts "Error: Invalid config file."
          exit!
        end
        @config[:path] = FileUtils.pwd
        @config[:step_path] = last_dir2
        @config[:orig_path] = initial_dir
        break
      end

      last_dir2 = last_dir
      last_dir = FileUtils.pwd
      FileUtils.cd('..')
    end

    FileUtils.cd(initial_dir)
  end

  def run(args)
    args = ["help"] if args.empty?
    cmd_name = args.shift.downcase

    if cmd_name =~ /\A\d+\z/
      args.unshift(cmd_name)
      cmd_name = "ref"
    end

    if cmd = Snaptoken::Commands::LIST.find { |cmd| cmd.name == cmd_name }
      cmd.new(args, @config).run
    else
      puts "There is no '#{cmd_name}' command. Run `leg help` for help."
    end
  end
end

