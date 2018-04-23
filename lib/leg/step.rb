module Leg
  class Step
    attr_accessor :number, :summary, :text, :diffs

    def initialize(number, summary, text, diffs)
      @number = number
      @summary = summary.strip
      @text = text.strip
      @diffs = diffs
    end

    def to_patch(options = {})
      @diffs.map { |diff| diff.to_patch(options) }.join("\n")
    end
  end
end
