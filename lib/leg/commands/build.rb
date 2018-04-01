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

        templates = Dir[File.join(@config.path, "template{,-?*}")].map do |template_dir|
          [template_dir, File.basename(template_dir).split("-")[1] || "html"]
        end
        if templates.empty?
          templates = [[nil, "html"], [nil, "md"]]
        end

        FileUtils.rm_rf(File.join(@config.path, "build"))
        templates.each do |template_dir, format|
          FileUtils.cd(@config.path) do
            FileUtils.mkdir_p("build/#{format}")

            include_default_css = (format == "html")
            page_template = Leg::DefaultTemplates::PAGE[format]
            if template_dir && File.exist?(File.join(template_dir, "page.#{format}.erb"))
              page_template = File.read(File.join(template_dir, "page.#{format}.erb"))
              include_default_css = false
            end
            page_template.gsub!(/\\\s*/, "")

            step_template = Leg::DefaultTemplates::STEP[format]
            if template_dir && File.exist?(File.join(template_dir, "step.#{format}.erb"))
              step_template = File.read(File.join(template_dir, "step.#{format}.erb"))
            end
            step_template.gsub!(/\\\s*/, "")

            tutorial.pages.each do |page|
              print "\r\e[K[Tutorial -> build/] Page #{page.filename}" unless @opts[:quiet]

              output = Leg::Template.render_page(page_template, step_template, format, page, tutorial, @config)
              File.write("build/#{format}/#{page.filename}.#{format}", output)
            end
            puts unless @opts[:quiet]

            if template_dir
              FileUtils.cd(template_dir) do
                Dir["*"].each do |f|
                  name = File.basename(f)

                  next if ["page.#{format}.erb", "step.#{format}.erb"].include? name
                  next if name.start_with? "_"

                  # XXX: currently only processes top-level ERB template files.
                  if name.end_with? ".erb"
                    output = Leg::Template.render(File.read(f), tutorial, @config)
                    File.write("../build/#{format}/#{name[0..-5]}", output)
                  else
                    FileUtils.cp_r(f, "../build/#{format}/#{name}")
                  end
                end
              end
            end

            if include_default_css && !File.exist?("build/#{format}/style.css")
              output = Leg::Template.render(Leg::DefaultTemplates::CSS, tutorial, @config)
              File.write("build/#{format}/style.css", output)
            end
          end
        end
      end
    end
  end
end
