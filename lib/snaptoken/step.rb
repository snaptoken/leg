class Snaptoken::Step
  attr_accessor :number, :text, :diffs

  def initialize(number, text, diffs)
    @number = number
    @text = text.strip
    @diffs = diffs
  end

  def to_html(template, config, offline)
    summary = @text.lines.first.strip
    text_after_summary = @text.lines[1..-1].join("\n").strip

    Snaptoken::Template.render_template(template,
      config: config,
      offline: offline,
      number: @number,
      summary: summary,
      text: text_after_summary,
      full_text: @text,
      diffs: @diffs
    )
  end

  def to_patch(options = {})
    @diffs.map { |diff| diff.to_patch(options) }.join("\n")
  end

  def syntax_highlight!
    @diffs.each(&:syntax_highlight!)
  end
end
