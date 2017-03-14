class Leg::Commands::Doc < Leg::Commands::BaseCommand
  def self.name
    "doc"
  end

  def self.summary
    "Renders files in doc folder into an HTML book"
  end

  def run
    needs! :config, :config_title, :steps_folder, :steps, :doc

    FileUtils.cd(File.join(@config[:path], "doc")) do
      FileUtils.rm_rf("html_out")
      FileUtils.mkdir("html_out")

      copy_static_files
      write_css
      write_html_files(prerender_diffs)
    end
  end

  class HTMLLineByLine < Rouge::Formatter
    def initialize(formatter)
      @formatter = formatter
    end

    def stream(tokens, &b)
      token_lines(tokens) do |line|
        line.each do |tok, val|
          yield @formatter.span(tok, val)
        end
        yield "\n"
      end
    end
  end

  private

  def copy_static_files
    Dir["html_in/*"].each do |f|
      name = File.basename(f)
      unless %w(template.html style.css).include? name
        FileUtils.cp_r(f, "html_out/#{name}")
      end
    end
  end

  def write_css
    @config[:rouge_theme] ||= "github"
    if @config[:rouge_theme].is_a? String
      theme = Rouge::Theme.find(@config[:rouge_theme])
    elsif @config[:rouge_theme].is_a? Hash
      theme = Class.new(Rouge::Themes::Base16)
      theme.name "base16.custom"
      theme.palette @config[:rouge_theme]
    end

    css = File.read("html_in/style.css")
    css << theme.render(scope: ".highlight")

    File.write("html_out/style.css", css)
  end

  def prerender_diffs
    diffs = {}
    FileUtils.cd("../steps") do
      FileUtils.mkdir_p("0")
      last_step = "0"
      Dir["*"].sort_by(&:to_i).each do |step|
        names = [step.to_i.to_s]
        if step =~ /\d+\-([\w-]+)$/
          names << $1
        end

        diff = Leg::Diff.new(last_step, step)

        names.each do |name|
          diffs[name] = diff.html.values.join("\n")
        end

        last_step = step
      end
      FileUtils.rmdir("0")
    end
    diffs
  end

  def write_html_files(diffs)
    html_template = File.read("html_in/template.html")

    index = ""
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    Dir["*.md"].sort.each do |md_file|
      html_file = md_file.sub(/\.md$/, '.html')

      md = File.read(md_file)
      md =~ /^# (.+)$/
      title = $1

      index << "<li><a href='#{html_file}'>#{title}</a></li>\n"

      content = markdown.render(md)
      content.gsub!(/<p>{{([\w-]+)}}<\/p>/) { diffs[$1] }

      html = html_template.dup
      html.gsub!("{{title}}") { "#{@config[:title]} | #{title}" }
      html.gsub!("{{content}}") { content }

      File.write(File.join("html_out", html_file), html)
    end

    content = <<~HTML
    <h1>#{@config[:title]}</h1>
    <h2>Table of Contents</h2>
    <ol>
      #{index}
    </ol>
    HTML

    html = html_template.dup
    html.gsub!("{{title}}", @config[:title])
    html.gsub!("{{content}}", content)

    File.write("html_out/index.html", html)
  end
end

