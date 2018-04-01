module Leg
  module Template
    def self.render(template_source, tutorial, config, params = {})
      Leg::Template::Context.new(template_source, tutorial, config, params).render_template
    end

    def self.render_page(page_template, step_template, format, page, tutorial, config)
      content = ""
      page.steps.each do |step|
        if !step.text.strip.empty?
          output = step.text.strip + "\n\n"
          if format == "html"
            output = Leg::Markdown.render(output)
          end
          content << output
        end

        step.syntax_highlight!
        content << Leg::Template.render_step(step_template, step, tutorial, config)
      end
      if page.footer_text
        # TODO: DRY this up. Please.
        output = page.footer_text.strip + "\n\n"
        if format == "html"
          output = Leg::Markdown.render(output)
        end
        content << output
      end

      page_number = tutorial.pages.index(page) + 1

      Leg::Template.render(page_template, tutorial, config,
        page_title: page.title,
        content: content,
        page_number: page_number,
        prev_page: page_number > 1 ? tutorial.pages[page_number - 2] : nil,
        next_page: page_number < tutorial.pages.length ? tutorial.pages[page_number] : nil
      )
    end

    def self.render_step(step_template, step, tutorial, config)
      Leg::Template.render(step_template, tutorial, config,
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
