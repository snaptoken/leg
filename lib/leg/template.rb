module Leg
  module Template
    def self.render(template_source, tutorial, config, params = {})
      Leg::Template::Context.new(template_source, tutorial, config, params).render_template
    end

    def self.render_page(page, tutorial, config)
      content = ""
      page.steps.each do |step|
        if !step.text.strip.empty?
          html = Leg::Markdown.render(step.text)
          html.gsub!(/<p>{{step (\d+)}}<\/p>/) do
            step = tutorial.step($1.to_i)
            step.syntax_highlight!
            Leg::Template.render_step(step, tutorial, config)
          end
          content << html
        end

        step.syntax_highlight!
        content << Leg::Template.render_step(step, tutorial, config)
      end
      if @footer_text
        # TODO: DRY this up. Please.
        html = Leg::Markdown.render(page.footer_text)
        html.gsub!(/<p>{{step (\d+)}}<\/p>/) do
          step = tutorial.step($1.to_i)
          step.syntax_highlight!
          Leg::Template.render_step(step, tutorial, config)
        end
        content << html
      end

      page_number = tutorial.pages.index(page) + 1

      Leg::Template.render(tutorial.page_template, tutorial, config,
        #offline: offline,
        page_title: page.title,
        content: content,
        page_number: page_number,
        prev_page: page_number > 1 ? tutorial.pages[page_number - 2] : nil,
        next_page: page_number < tutorial.pages.length ? tutorial.pages[page_number] : nil
      )
    end

    def self.render_step(step, tutorial, config)
      Leg::Template.render(tutorial.step_template, tutorial, config,
        #offline: offline,
        number: step.number,
        summary: step.summary,
        diffs: step.diffs
      )
    end

    class Context
      def initialize(template_source, tutorial, config, params)
        @template_source = template_source
        @tutorial = tutorial
        @config = config
        @params = params
      end

      def render_template
        b = binding
        @config.options.merge(@params).each do |name, value|
          b.local_variable_set(name, value)
        end
        ERB.new(@template_source).result(b)
      end

      def render(path)
        if !path.end_with? ".md"
          raise ArgumentError, "Only .md files are supported by render() at the moment."
        end

        contents = File.read(path)
        Leg::Markdown.render(contents)
      end

      def markdown(source)
        Leg::Markdown.render(source)
      end

      def pages
        @tutorial.pages
      end

      def step(number)
        step = @tutorial.step(number)
        step.syntax_highlight!
        step.to_html(@tutorial, @params[:offline])
      end

      def syntax_highlighting_css(scope)
        syntax_theme = @config.options[:syntax_theme] || "github"
        if syntax_theme.is_a? String
          theme = Rouge::Theme.find(syntax_theme)
        elsif syntax_theme.is_a? Hash
          theme = Class.new(Rouge::Themes::Base16)
          theme.name "base16.custom"
          theme.palette syntax_theme
        end

        theme.render(scope: scope)
      end
    end
  end
end
