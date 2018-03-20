class Snaptoken::CLI
  CONFIG_FILE = "leg.yml"

  def initialize
    initial_dir = FileUtils.pwd

    @tutorial = nil
    last_dir = nil
    while FileUtils.pwd != last_dir
      if File.exist?(CONFIG_FILE)
        config = YAML.load_file(CONFIG_FILE)
        if config == false
          puts "Error: Invalid config file."
          exit!
        end
        config = {} unless config.is_a?(Hash)
        config[:path] = FileUtils.pwd
        config = symbolize_keys(config)
        @tutorial = Snaptoken::Tutorial.new(config)
        break
      end

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
      cmd_name = "step"
    end

    if cmd = Snaptoken::Commands::LIST.find { |cmd| cmd.name == cmd_name }
      cmd.new(args, @tutorial).run
    else
      puts "There is no '#{cmd_name}' command. Run `leg help` for help."
    end
  end

  private

  def symbolize_keys(value)
    case value
    when Hash
      value.map do |k, v|
        [k.to_sym, symbolize_keys(v)]
      end.to_h
    when Array
      value.map { |v| symbolize_keys(v) }
    else
      value
    end
  end
end

