module Leg
  module Commands
    class Build < BaseCommand
      def self.name
        "build"
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

        needs! :config, :repo

        tutorial = @git.load!(full_diffs: true, diffs_ignore_whitespace: true) do |step_num|
          print "\r\e[K[repo/ -> Tutorial] Step #{step_num}" unless @opts[:quiet]
        end
        puts unless @opts[:quiet]

        num_steps = tutorial.num_steps

        if @config.options[:diff_transformers]
          transformers = @config.options[:diff_transformers].map do |transformer_config|
            if transformer_config.is_a? String
              transformer = transformer_config
              options = {}
            else
              transformer = transformer_config.keys.first
              options = transformer_config.values.first
            end
            Leg::DiffTransformers.const_get(transformer).new(options)
          end

          tutorial.transform_diffs(transformers) do |step_num|
            print "\r\e[K[Transform diffs] Step #{step_num}/#{num_steps}" unless @opts[:quiet]
          end
          puts unless @opts[:quiet]
        end

        FileUtils.mkdir_p(File.join(@config.path, "template"))
        FileUtils.cd(File.join(@config.path, "template")) do
          FileUtils.rm_rf("../build")
          FileUtils.mkdir_p("../build/html")

          include_default_css = true
          if File.exist?("page.html.erb")
            tutorial.page_template = File.read("page.html.erb")
            include_default_css = false
          end

          if File.exist?("step.html.erb")
            tutorial.step_template = File.read("step.html.erb")
          end
          tutorial.step_template.gsub!(/\\\s*/, "")

          tutorial.pages.each do |page|
            print "\r\e[K[Tutorial -> build/] Page #{page.filename}" unless @opts[:quiet]

            html = Leg::Template.render_page(page, tutorial, @config)
            File.write("../build/html/#{page.filename}.html", html)
          end
          puts unless @opts[:quiet]

          Dir["*"].each do |f|
            name = File.basename(f)

            next if %w(page.html.erb step.html.erb).include? name
            next if name.start_with? "_"

            # XXX: currently only processes top-level ERB template files.
            if name.end_with? ".erb"
              output = Leg::Template.render(File.read(f), tutorial, @config)
              File.write("../build/html/#{name[0..-5]}", output)
            else
              FileUtils.cp_r(f, "../build/html/#{name}")
            end
          end

          if include_default_css && !File.exist?("../build/html/style.css")
            output = Leg::Template.render(Leg::DefaultTemplates::CSS, tutorial, @config)
            File.write("../build/html/style.css", output)
          end
        end
      end
    end
  end
end
