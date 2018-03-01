class Snaptoken::Commands::Doc < Snaptoken::Commands::BaseCommand
  def self.name
    "doc"
  end

  def self.summary
    "Render repo/ into an HTML or Markdown book."
  end

  def self.usage
    "[-q]"
  end

  def setopts!(o)
    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config, :repo

    FileUtils.cd(File.join(@config[:path], "template")) do
      FileUtils.rm_rf("../build")
      FileUtils.mkdir_p("../build/html")
      FileUtils.mkdir_p("../build/html-offline")

      page_template = Snaptoken::DefaultTemplates::PAGE
      include_default_css = true
      if File.exist?("page.html.erb")
        page_template = File.read("page.html.erb")
        include_default_css = false
      end

      step_template = Snaptoken::DefaultTemplates::STEP
      if File.exist?("step.html.erb")
        step_template = File.read("step.html.erb")
      end
      step_template.gsub!(/\\\s*/, "")

      tutorial = Snaptoken::Tutorial.from_repo("../repo", full_diffs: true, diffs_ignore_whitespace: true)

      tutorial.pages.each do |page|
        html = page.to_html(page_template, step_template, @config, tutorial.pages, false)
        File.write("../build/html/#{page.filename}.html", html)

        offline_html = page.to_html(page_template, step_template, @config, tutorial.pages, true)
        File.write("../build/html-offline/#{page.filename}.html", offline_html)
      end

      template_params = {
        config: config,
        pages: tutorial.pages,
        syntax_highlighting_css: syntax_highlighting_css(".highlight")
      }

      Dir["*"].each do |f|
        name = File.basename(f)

        next if %w(page.html.erb step.html.erb).include? name
        next if name.start_with? "_"

        # XXX: currently only processes top-level ERB template files.
        if name.end_with? ".erb"
          output = Snaptoken::Template.render_template(File.read(f), template_params.merge(offline: false))
          File.write("../build/html/#{name[0..-5]}", output)

          output = Snaptoken::Template.render_template(File.read(f), template_params.merge(offline: true))
          File.write("../build/html-offline/#{name[0..-5]}", output)
        else
          FileUtils.cp_r(f, "../build/html/#{name}")
          FileUtils.cp_r(f, "../build/html-offline/#{name}")
        end
      end

      if include_default_css && !File.exist?("../build/html/style.css")
        output = Snaptoken::Template.render_template(Snaptoken::DefaultTemplates::CSS, template_params.merge(offline: false))
        File.write("../build/html/style.css", output)
      end
      if include_default_css && !File.exist?("../build/html-offline/style.css")
        output = Snaptoken::Template.render_template(Snaptoken::DefaultTemplates::CSS, template_params.merge(offline: true))
        File.write("../build/html-offline/style.css", output)
      end
    end
  end

  private

  def syntax_highlighting_css(scope)
    @config[:rouge_theme] ||= "github"
    if @config[:rouge_theme].is_a? String
      theme = Rouge::Theme.find(@config[:rouge_theme])
    elsif @config[:rouge_theme].is_a? Hash
      theme = Class.new(Rouge::Themes::Base16)
      theme.name "base16.custom"
      theme.palette @config[:rouge_theme]
    end

    theme.render(scope: scope)
  end
end
