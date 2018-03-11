class Snaptoken::Page
  attr_accessor :filename, :content

  def initialize(filename = nil)
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

  def to_html(tutorial, offline)
    content = ""
    @content.each do |step_or_text|
      case step_or_text
      when Snaptoken::Step
        step_or_text.syntax_highlight!
        content << step_or_text.to_html(tutorial, offline)
      when String
        html = Snaptoken::Markdown.render(step_or_text)
        html.gsub!(/<p>{{step (\d+)}}<\/p>/) do
          step = tutorial.step($1.to_i)
          step.syntax_highlight!
          step.to_html(tutorial, offline)
        end
        content << html
      else
        raise "unexpected content type"
      end
    end

    page_number = tutorial.pages.index(self) + 1

    Snaptoken::Template.new(tutorial.page_template, tutorial,
      offline: offline,
      page_title: title,
      content: content,
      page_number: page_number,
      prev_page: page_number > 1 ? tutorial.pages[page_number - 2] : nil,
      next_page: page_number < tutorial.pages.length ? tutorial.pages[page_number] : nil
    ).render_template
  end
end
