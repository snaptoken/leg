module Leg
  class Step
    attr_accessor :number, :summary, :text, :diffs

    def initialize(number, summary, text, diffs)
      @number = number
      @summary = summary.strip
      @text = text.strip
      @diffs = diffs
    end

    def to_html(tutorial, offline)
      Leg::Template.new(tutorial.step_template, tutorial,
        offline: offline,
        number: @number,
        summary: @summary,
        diffs: @diffs
      ).render_template
    end

    def to_patch(options = {})
      @diffs.map { |diff| diff.to_patch(options) }.join("\n")
    end

    def syntax_highlight!
      @diffs.each(&:syntax_highlight!)
    end
  end
end
