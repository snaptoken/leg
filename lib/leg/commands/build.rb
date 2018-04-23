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
        needs! :config, :repo

        tutorial = @git.load!(full_diffs: true, diffs_ignore_whitespace: true) do |step_num|
          output "\r\e[K[repo/ -> Tutorial] Step #{step_num}"
        end
        output "\n"

        num_steps = tutorial.num_steps

        if @config.options[:diff_transformers].nil?
          @config.options[:diff_transformers] = [
            { 'FoldSections' => {
              unfold_before_new_section: true,
              section_types: [
                { name: 'comments', start: "^/\\*\\*\\*.+\\*\\*\\*/$", end: nil },
                { name: 'braces', start: "^\\S.*{$", end: "^}( \\w+)?;?$" }
              ]
            }},
            'TrimBlankLines',
            'OmitAdjacentRemovals'
          ]
        end

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
            output "\r\e[K[Transform diffs] Step #{step_num}/#{num_steps}"
          end
          output "\n"
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
              output "\r\e[K[Tutorial -> build/] Page #{page.filename}"

              content = Leg::Template.render_page(page_template, step_template, format, page, tutorial, @config)
              File.write("build/#{format}/#{page.filename}.#{format}", content)
            end
            output "\n"

            if template_dir
              FileUtils.cd(template_dir) do
                Dir["*"].each do |f|
                  name = File.basename(f)

                  next if ["page.#{format}.erb", "step.#{format}.erb"].include? name
                  next if name.start_with? "_"

                  # XXX: currently only processes top-level ERB template files.
                  if name.end_with? ".erb"
                    content = Leg::Template.render(File.read(f), tutorial, @config)
                    File.write("../build/#{format}/#{name[0..-5]}", content)
                  else
                    FileUtils.cp_r(f, "../build/#{format}/#{name}")
                  end
                end
              end
            end

            if include_default_css && !File.exist?("build/#{format}/style.css")
              content = Leg::Template.render(Leg::DefaultTemplates::CSS, tutorial, @config)
              File.write("build/#{format}/style.css", content)
            end
          end
        end
      end
    end
  end
end
