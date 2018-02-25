class Snaptoken::Page
  attr_accessor :filename, :content

  def initialize(filename)
    @filename = filename
    @content = []
  end

  def <<(step_or_text)
    @content << step_or_text
    self
  end

  def empty?
    @content.empty?
  end

  def title
    if @content.first.is_a?(String) && @content.first.lines.first.start_with?("# ")
      @content.first.lines.first[2..-1].strip
    end
  end

  def to_html(template, step_template, config, pages, offline)
    content = ""
    @content.each do |step_or_text|
      case step_or_text
      when Snaptoken::Step
        step_or_text.syntax_highlight!
        content << step_or_text.to_html(step_template, config, offline)
      when String
        content << Snaptoken::Markdown.render(step_or_text)
      else
        raise "unexpected content type"
      end
    end

    page_number = pages.index(self) + 1
    prev_page = page_number > 1 ? pages[page_number - 2] : nil
    next_page = page_number < pages.length ? pages[page_number] : nil

    ERB.new(template).result(binding)
  end
end
