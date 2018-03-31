module Leg
  class Template
    attr_reader :tutorial

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
