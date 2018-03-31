module Leg
  class Config
    attr_reader :path, :options

    def initialize(path)
      @path = path
    end

    def load!
      @options = YAML.load_file(File.join(@path, "leg.yml"))
      @options = {} unless @options.is_a? Hash
      @options = symbolize_keys(@options)
    end

    def last_synced_at
      File.mtime(last_synced_path) if File.exist?(last_synced_path)
    end

    def synced!
      FileUtils.touch(last_synced_path)
    end

    private

    def last_synced_path
      File.join(@path, ".leg/last_synced")
    end

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
end
