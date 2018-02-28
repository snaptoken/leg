module Snaptoken::Template
  class << self
    def render_template(template, params)
      b = binding
      params.each do |name, value|
        b.local_variable_set(name, value)
      end
      ERB.new(template).result(b)
    end

    def render(path)
      if !path.end_with? ".md"
        raise ArgumentError, "Only .md files are supported by render() at the moment."
      end

      contents = File.read(path)
      Snaptoken::Markdown.render(contents)
    end
  end
end
