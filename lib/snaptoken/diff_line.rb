class Snaptoken::DiffLine
  TYPES = [:added, :removed, :unchanged, :folded]

  attr_reader :type, :source, :line_numbers
  attr_writer :source, :line_numbers

  def initialize(type, source, line_numbers)
    unless TYPES.include? type
      raise ArgumentError, "type must be one of: #{TYPES.inspect}"
    end
    @type = type
    @source = source.chomp
    @line_numbers = line_numbers
  end

  def type=(type)
    unless TYPES.include? type
      raise ArgumentError, "type must be one of: #{TYPES.inspect}"
    end
    @type = type
  end

  def blank?
    @source.strip.empty?
  end
end
