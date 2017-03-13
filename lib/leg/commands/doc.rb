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

  private

  def copy_static_files
    Dir["html_in/*"].each do |f|
      name = File.basename(f)
      unless %w(template.html style.css).include? name
        FileUtils.cp(f, "html_out/#{name}")
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

        diffout = []
        section_stack = []
        in_diff = false
        lexer = nil
        formatter = Rouge::Formatters::HTML.new

        diff = `git diff --histogram --unified=100000 --ignore-space-change --no-index #{last_step} #{step}`
        diff.lines.each do |line|
          if !in_diff && line =~ /^\+\+\+ (.+)$/
            filename = File.basename($1)
            lexer = Rouge::Lexer.guess(filename: filename)
            diffout << {type: :section, section_type: :file, summary: filename, content: []}
            section_stack = [diffout.last]
          elsif line.start_with? '@@'
            in_diff = true
          elsif in_diff && [' ', '+', '-'].include?(line[0])
            line_hl = formatter.format(lexer.lex(line[1..-1])).gsub("\n", "")
            type = {' ' => :nochange, '+' => :add, '-' => :remove }[line[0]]

            section_stack.each { |s| s[:dirty] = true } if type != :nochange

            if line[1..-1] =~ /^\/\*\*\* (.+) \*\*\*\/$/
              section_stack = [section_stack[0]]
              section_stack.last[:content] << {type: :section, section_type: :comment, summary: line[1..-1].chomp, content: []}
              section_stack.push(section_stack.last[:content].last)
            elsif line[1] =~ /\S/ && line.chomp[-1] == "{"
              section_stack.pop if section_stack.length > 1 && section_stack.last[:section_type] == :braces
              section_stack.last[:content] << {type: :section, section_type: :braces, summary: line[1..-1].chomp + " ... ", content: []}
              section_stack.push(section_stack.last[:content].last)
            end

            section_stack.last[:content] << {type: type, content: line_hl}

            if line[1..-1] =~ /^(}( \w+)?;?)$/ && section_stack.last[:section_type] == :braces
              s = section_stack.pop
              s[:summary] << $1
            end

            section_stack.each { |s| s[:dirty] = true } if type != :nochange
          else
            in_diff = false
          end
        end

        change_chain = []
        diffout.each do |file|
          to_render = file[:content].dup
          until to_render.empty?
            cur = to_render.shift
            if cur[:type] == :section
              if cur[:dirty]
                to_render = cur[:content] + to_render
              else
                if change_chain.first && change_chain.first[:content].empty?
                  change_chain.first[:type] = :nochange
                end
                if change_chain.last && change_chain.last[:content].empty?
                  change_chain.last[:type] = :nochange
                end
                change_chain = []
              end
            else
              if cur[:type] == :nochange
                if change_chain.first && change_chain.first[:content].empty?
                  change_chain.first[:type] = :nochange
                end
                if change_chain.last && change_chain.last[:content].empty?
                  change_chain.last[:type] = :nochange
                end
                change_chain = []
              else
                change_chain << cur
                if cur[:type] == :add
                  change_chain.each { |c| c[:omit] = true if c[:type] == :remove }
                elsif cur[:type] == :remove
                  cur[:omit] = true if change_chain.any? { |c| c[:type] == :add }
                end
              end
            end
          end
        end

        html = ""
        diffout.each do |file|
          html << "<div class=\"diff\">\n"
          html << "<div class=\"filename\">#{file[:summary]}</div>\n"
          html << "<pre class=\"highlight\"><code>"

          to_render = file[:content].dup
          until to_render.empty?
            cur = to_render.shift
            if cur[:type] == :section
              if cur[:dirty]
                to_render = cur[:content] + to_render
              else
                summary = formatter.format(lexer.lex(cur[:summary])).gsub("\n", "")
                html << "<div class=\"line folded\">#{summary}</div>"
              end
            elsif !cur[:omit]
              tag = {nochange: :div, add: :ins, remove: :del}[cur[:type]]
              html << "<#{tag} class=\"line\">#{cur[:content]}</#{tag}>"
            end
          end

          html << "</code></pre>\n</div>\n"
        end

        names.each do |name|
          diffs[name] = html
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

