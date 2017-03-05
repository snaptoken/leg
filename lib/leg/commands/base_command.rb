class Leg::Commands::BaseCommand
  def initialize(args, config)
    @args = args
    @config = config
  end

  def self.name; raise NotImplementedError; end
  def self.summary; raise NotImplementedError; end
  def run; raise NotImplementedError; end

  def self.inherited(subclass)
    Leg::Commands::LIST << subclass
  end

  ERROR_MSG = {
    config: "You are not in a leg working directory.",
    config_build: "Config file doesn't have build instructions.",
    config_run: "Config file doesn't have run instructions.",
    config_clean: "Config file doesn't have cleaning instructions.",
    config_editor: "Config file doesn't specify a text editor."
  }

  def needs!(what)
    valid = false

    case what
    when :config
      valid = true if @config
    when :config_build
      valid = true if @config[:build]
    when :config_run
      valid = true if @config[:run]
    when :config_clean
      valid = true if @config[:clean]
    when :config_editor
      valid = true if @config[:editor]
    else
      raise NotImplementedError
    end

    if !valid
      puts "Error: " + ERROR_MSG[what]
      exit!
    end
  end

  def shell_command(*cmd, exec: false, echo: true, exit_on_failure: true)
    if exec
      exec(*cmd)
    else
      puts cmd if echo
      success = system(*cmd)
      exit! if !success && exit_on_failure
    end
  end

  def steps
    @steps ||= Dir[File.join(@config[:path], "*")].map do |f|
      name = File.basename(f)
      name if File.directory?(f) && name =~ /\A\d+(\.\d+)*\z/
    end.compact.sort_by { |s| s.split(".").map(&:to_i) }
  end

  def current_step
    if @config[:step_path]
      File.basename(@config[:step_path])
    end
  end

  def latest_step
    steps.last
  end

  def current_or_latest_step
    current_step || latest_step
  end

  def step_path(step)
    File.join(@config[:path], step)
  end

  def select_step(step, &block)
    puts "Selecting step: #{step}"
    FileUtils.cd(step_path(step), &block)
  end
end

