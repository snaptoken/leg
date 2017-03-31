class Snaptoken::Commands::Doc < Snaptoken::Commands::BaseCommand
  def self.name
    "doc"
  end

  def self.summary
    "Renders files in doc folder into an HTML book"
  end

  def run
    needs! :config, :config_name, :config_title, :steps_folder, :steps, :doc

    FileUtils.cd(File.join(@config[:path], "doc")) do
      unless @args.include? "-c"
        FileUtils.rm_rf("html_out")
        FileUtils.mkdir("html_out")
      end

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
      unless %w(template.html template_index.html style.css).include? name
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

    theme_css = theme.render(scope: ".highlight")
    if @config[:bold_weight]
      theme_css.gsub!("font-weight: bold;", "font-weight: #{@config[:bold_weight]}")
    end

    css = File.read("html_in/style.css")
    css << theme_css

    File.write("html_out/style.css", css)
  end

  def prerender_diffs
    if @args.include? "-c"
      return Marshal.load(File.read("../.cached-diffs"))
    end

    diffs = {}
    FileUtils.cd("../steps") do
      FileUtils.mkdir_p("0")
      last_step = Snaptoken::Step.new(0, nil, [])
      steps.each do |step|
        print "\r\e[K#{step.folder_name}"

        diff = Snaptoken::Diff.new(@config, last_step, step)

        diffs[step.name] = diff.html.values.join("\n")

        last_step = step
      end
      puts
      FileUtils.rmdir("0")
    end
    File.write("../.cached-diffs", Marshal.dump(diffs))
    diffs
  end

  def write_html_files(diffs)
    html_template = File.read("html_in/template.html")

    index = ""
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    pages = Dir["*.md"].sort.map { |f| f.sub(/\.md$/, '') }
    pages.delete "00.index"
    pages.each.with_index do |page, idx|
      md = File.read("#{page}.md")
      md =~ /^# (.+)$/
      title = $1

      index << "<li><a href='#{page}.html'>#{title}</a></li>\n"

      prev_link = "<a href='#'></a>"
      if idx > 0
        prev_link = "<a href='#{pages[idx-1]}.html'>&larr; prev</a>"
      end

      next_link = "<a href='#'></a>"
      if idx < pages.length - 1
        next_link = "<a href='#{pages[idx+1]}.html'>next &rarr;</a>"
      end

      content = markdown.render(md)
      content = Redcarpet::Render::SmartyPants.render(content)
      content.gsub!(/<p>{{([\w-]+)}}<\/p>/) { diffs[$1] }

      html = html_template.dup
      html.gsub!("{{title}}") { "#{idx+1}. #{title} | #{@config[:title]}" }
      html.gsub!("{{prev_link}}") { prev_link }
      html.gsub!("{{next_link}}") { next_link }
      html.gsub!("{{content}}") { content }

      File.write(File.join("html_out", "#{page}.html"), html)
    end

    content = markdown.render(File.read("00.index.md"))
    content = Redcarpet::Render::SmartyPants.render(content)
    content.gsub!(/<p>{{toc}}<\/p>/) { "<ol>#{index}</ol>" }

    if File.exist?("html_in/template_index.html")
      html = File.read("html_in/template_index.html")
    else
      html = html_template.dup
    end

    html.gsub!("{{title}}") { "Table of contents | #{@config[:title]}" }
    html.gsub!("{{prev_link}}") { "<a href='#'></a>" }
    html.gsub!("{{next_link}}") { "<a href='#{pages.first}.html'>next &rarr;</a>" }
    html.gsub!("{{content}}") { content }

    File.write("html_out/index.html", html)
  end
end

