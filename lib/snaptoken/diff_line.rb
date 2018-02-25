class Snaptoken::DiffLine
  TYPES = [:added, :removed, :unchanged, :folded]

  attr_reader :type, :line, :line_numbers

  def initialize(type, line, line_numbers)
    unless TYPES.include? type
      raise ArgumentError, "type must be one of: #{TYPES.inspect}"
    end
    @type = type
    @line = line
    @line_numbers = line_numbers
  end

  def type=(type)
    unless TYPES.include? type
      raise ArgumentError, "type must be one of: #{TYPES.inspect}"
    end
    @type = type
  end

  def blank?
    @line.strip.empty?
  end
end
