module Leg
  class Page
    attr_accessor :filename, :steps, :footer_text

    def initialize(filename = "tutorial")
      @filename = filename
      @steps = []
      @footer_text = nil
    end

    def <<(step)
      @steps << step
      self
    end

    def empty?
      @steps.empty?
    end

    def title
      first_line = @steps.first ? @steps.first.text.lines.first : (@footer_text ? @footer_text.lines.first : nil)
      if first_line && first_line.start_with?("# ")
        first_line[2..-1].strip
      end
    end

    def to_html(tutorial, config, offline)
      content = ""
      @steps.each do |step|
        if !step.text.strip.empty?
          html = Leg::Markdown.render(step.text)
          html.gsub!(/<p>{{step (\d+)}}<\/p>/) do
            step = tutorial.step($1.to_i)
            step.syntax_highlight!
            step.to_html(tutorial, offline)
          end
          content << html
        end

        step.syntax_highlight!
        content << step.to_html(tutorial, config, offline)
      end
      if @footer_text
        # TODO: DRY this up. Please.
        html = Leg::Markdown.render(@footer_text)
        html.gsub!(/<p>{{step (\d+)}}<\/p>/) do
          step = tutorial.step($1.to_i)
          step.syntax_highlight!
          step.to_html(tutorial, config, offline)
        end
        content << html
      end

      page_number = tutorial.pages.index(self) + 1

      Leg::Template.new(tutorial.page_template, tutorial, config,
        offline: offline,
        page_title: title,
        content: content,
        page_number: page_number,
        prev_page: page_number > 1 ? tutorial.pages[page_number - 2] : nil,
        next_page: page_number < tutorial.pages.length ? tutorial.pages[page_number] : nil
      ).render_template
    end
  end
end
