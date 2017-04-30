class Snaptoken::Commands::BaseCommand
  def initialize(args, config)
    @args = args
    @config = config
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
      o.banner =  "Usage: leg #{self.class.name} #{self.class.usage}"
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
    config_sync: {
      true: "The :sync option in leg.yml must be set to 'repo' or 'steps'."
    },
    steps_folder: {
      true: "There is no steps folder.",
      false: "There is already a steps folder."
    },
    steps: {
      true: "There are no steps in the steps folder."
    },
    repo: {
      true: "There is no repo folder.",
      false: "There is already a repo folder."
    },
    diff: {
      true: "There is no steps.diff file."
    },
    doc: {
      true: "There is no doc folder."
    },
    doc_out: {
      true: "There are no doc output files."
    },
    cached_diffs: {
      true: "There are no cached diffs."
    },
    ftp: {
      true: "There is no ftp.yml file."
    }
  }

  def needs!(*whats)
    options = whats.pop if whats.last.is_a? Hash
    options ||= {}

    yes = Array(whats).flatten.map { |w| [w, true] }
    no = Array(options[:not]).map { |w| [w, false] }

    (yes + no).each do |what, v|
      valid = false
      case what
      when :config
        valid = true if @config
      when :config_sync
        valid = true if %w(repo steps).include?(@config[:sync])
      when :steps_folder
        valid = true if File.exist?(File.join(@config[:path], "steps"))
      when :steps
        valid = true if steps.length > 0
      when :repo
        valid = true if File.exist?(File.join(@config[:path], "repo"))
      when :diff
        valid = true if File.exist?(File.join(@config[:path], "steps.diff"))
      when :doc
        valid = true if File.exist?(File.join(@config[:path], "doc"))
      when :doc_out
        valid = true if File.exist?(File.join(@config[:path], "doc/html_out"))
      when :cached_diffs
        valid = true if File.exist?(File.join(@config[:path], ".cached-diffs"))
      when :ftp
        valid = true if File.exist?(File.join(@config[:path], "ftp.yml"))
      else
        raise NotImplementedError
      end

      if valid != v
        puts "Error: " + ERROR_MSG[what][v.to_s.to_sym]
        exit!
      end
    end
  end

  def steps
    @steps ||= Dir[File.join(@config[:path], "steps/*")].map do |f|
      Snaptoken::Step.from_folder_name(File.basename(f)) if File.directory?(f)
    end.compact.sort_by(&:number)
  end

  def current_step
    if @config[:step_path]
      Snaptoken::Step.from_folder_name(File.basename(@config[:step_path]))
    end
  end

  def latest_step
    steps.last
  end

  def current_or_latest_step
    current_step || latest_step
  end

  def step_path(step)
    File.join(@config[:path], "steps", step.folder_name)
  end

  def select_step(step, &block)
    puts "Selecting step: #{step.folder_name}"
    FileUtils.cd(step_path(step), &block)
  end
end

