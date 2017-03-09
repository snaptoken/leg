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
  }

  def needs!(what)
    valid = false

    case what
    when :config
      valid = true if @config
    else
      raise NotImplementedError
    end

    if !valid
      puts "Error: " + ERROR_MSG[what]
      exit!
    end
  end

  def steps
    @steps ||= Dir[File.join(@config[:path], "steps/*")].map do |f|
      name = File.basename(f)
      name if File.directory?(f) && name =~ /\A\d+(\.\d+)*(-\w+)*\z/
    end.compact.sort_by { |s| s.split(".").map(&:to_i) }.reject { |s| s.to_i.zero? }
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

  def step_name(step)
    parts = step.split('-')
    if parts.length > 1
      parts[1..-1].join('-')
    end
  end

  def step_path(step)
    File.join(@config[:path], "steps", step)
  end

  def select_step(step, &block)
    puts "Selecting step: #{step}"
    FileUtils.cd(step_path(step), &block)
  end
end

