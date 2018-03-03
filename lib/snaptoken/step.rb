class Snaptoken::Step
  attr_accessor :number, :text, :diffs

  def initialize(number, text, diffs)
    @number = number
    @text = text.strip
    @diffs = diffs
  end

  def to_html(tutorial, offline)
    summary = (@text.lines.first || "").strip
    text_after_summary = (@text.lines[1..-1] || []).join.strip

    Snaptoken::Template.new(tutorial.step_template, tutorial,
      offline: offline,
      number: @number,
      summary: summary,
      text: text_after_summary,
      full_text: @text,
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
