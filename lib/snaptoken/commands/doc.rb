class Snaptoken::Commands::Doc < Snaptoken::Commands::BaseCommand
  SECTION_COMMENT = {
    start: /^\/\*\*\*.+\*\*\*\/$/,
    end: false,
  }

  SECTION_BRACES = {
    start: /^\S.*{$/,
    end: /^}( \w+)?;?$/
  }

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
    args = @opts[:quiet] ? ["--quiet"] : []
    Snaptoken::Commands::Sync.new(args, @tutorial).run

    needs! :config, :repo

    @tutorial.load_from_repo(full_diffs: true, diffs_ignore_whitespace: true) do |step_num|
      print "\r\e[K[repo/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
    end
    puts unless @opts[:quiet]

    num_steps = @tutorial.num_steps

    @tutorial.transform_diffs([
      Snaptoken::DiffTransformers::FoldSections.new([SECTION_COMMENT, SECTION_BRACES]),
      Snaptoken::DiffTransformers::TrimBlankLines.new,
      Snaptoken::DiffTransformers::OmitAdjacentRemovals.new
    ]) do |step_num|
      print "\r\e[K[Transform diffs] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
    end
    puts unless @opts[:quiet]

    FileUtils.cd(File.join(@tutorial.path, "template")) do
      FileUtils.rm_rf("../build")
      FileUtils.mkdir_p("../build/html")
      FileUtils.mkdir_p("../build/html-offline")

      include_default_css = true
      if File.exist?("page.html.erb")
        @tutorial.page_template = File.read("page.html.erb")
        include_default_css = false
      end

      if File.exist?("step.html.erb")
        @tutorial.step_template = File.read("step.html.erb")
      end
      @tutorial.step_template.gsub!(/\\\s*/, "")

      @tutorial.pages.each do |page|
        print "\r\e[K[Tutorial -> build/] Page #{page.filename}" unless @opts[:quiet]

        html = page.to_html(@tutorial, false)
        File.write("../build/html/#{page.filename}.html", html)

        offline_html = page.to_html(@tutorial, true)
        File.write("../build/html-offline/#{page.filename}.html", offline_html)
      end
      puts unless @opts[:quiet]

      Dir["*"].each do |f|
        name = File.basename(f)

        next if %w(page.html.erb step.html.erb).include? name
        next if name.start_with? "_"

        # XXX: currently only processes top-level ERB template files.
        if name.end_with? ".erb"
          output = Snaptoken::Template.new(File.read(f), @tutorial, offline: false).render_template
          File.write("../build/html/#{name[0..-5]}", output)

          output = Snaptoken::Template.new(File.read(f), @tutorial, offline: true).render_template
          File.write("../build/html-offline/#{name[0..-5]}", output)
        else
          FileUtils.cp_r(f, "../build/html/#{name}")
          FileUtils.cp_r(f, "../build/html-offline/#{name}")
        end
      end

      if include_default_css && !File.exist?("../build/html/style.css")
        output = Snaptoken::Template.new(Snaptoken::DefaultTemplates::CSS, @tutorial, offline: false).render_template
        File.write("../build/html/style.css", output)
      end
      if include_default_css && !File.exist?("../build/html-offline/style.css")
        output = Snaptoken::Template.new(Snaptoken::DefaultTemplates::CSS, @tutorial, offline: true).render_template
        File.write("../build/html-offline/style.css", output)
      end
    end
  end
end
