class Snaptoken::Step
  attr_accessor :name, :number, :diffs

  def initialize(name, number, diffs)
    @name = name
    @number = number
    @diffs = diffs
  end

  def to_html(template, config, offline)
    step_name = @name
    step_number = @number

    ERB.new(template).result(binding)
  end

  def syntax_highlight!
    @diffs.each(&:syntax_highlight!)
  end
end
