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

    FileUtils.cd(@config[:path]) do
      FileUtils.rm_rf("build")
      FileUtils.mkdir_p("build/html")
      FileUtils.mkdir_p("build/html-offline")

      page_template = Snaptoken::DefaultTemplates::PAGE
      include_default_css = true
      if File.exist?("template/page.html.erb")
        page_template = File.read("template/page.html.erb")
        include_default_css = false
      end

      step_template = Snaptoken::DefaultTemplates::STEP
      if File.exist?("template/step.html.erb")
        step_template = File.read("template/step.html.erb")
      end
      step_template.gsub!(/\\\s*/, "")

      repo = Rugged::Repository.new("repo")
      empty_tree = Rugged::Tree.empty(repo)

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)

      step_num = 1
      cur_page = Snaptoken::Page.new("steps.html")
      pages = []
      walker.each do |commit|
        commit_message = commit.message.strip
        next if commit_message == "-"
        summary = commit_message.lines.first.strip
        step_name = summary.split(' ').first # temporarararary
        last_commit = commit.parents.first
        diff = (last_commit || empty_tree).diff(commit, context_lines: 100_000, ignore_whitespace_change: true)
        patches = diff.each_patch.reject { |p| p.delta.new_file[:path] == ".dummyleg" }

        if patches.empty?
          if commit_message =~ /\A~~~ (.+)\z/
            pages << cur_page unless cur_page.empty?

            cur_page = Snaptoken::Page.new("#{$1}.html")
          else
            cur_page << commit_message
          end
        else
          patch = patches.map(&:to_s).join("\n")

          print "\r\e[K[repo/ -> build/] #{step_name}" unless @opts[:quiet]

          step_diffs = Snaptoken::Diff.parse(patch).map
          cur_page << Snaptoken::Step.new(step_name, step_num, step_diffs)

          step_num += 1
        end
      end
      print "\n" unless @opts[:quiet]
      pages << cur_page unless cur_page.empty?

      pages.each do |page|
        html = page.to_html(page_template, step_template, @config, pages, false)
        File.write("build/html/#{page.filename}", html)

        offline_html = page.to_html(page_template, step_template, @config, pages, true)
        File.write("build/html-offline/#{page.filename}", offline_html)
      end

      Dir["template/*"].each do |f|
        name = File.basename(f)
        unless %w(page.html.erb step.html.erb).include? name
          # XXX: currently only processes top-level ERB template files.
          if name.end_with? ".erb"
            offline = false
            File.write("build/html/#{name[0..-5]}", ERB.new(File.read(f)).result(binding))

            offline = true
            File.write("build/html-offline/#{name[0..-5]}", ERB.new(File.read(f)).result(binding))
          else
            FileUtils.cp_r(f, "build/html/#{name}")
            FileUtils.cp_r(f, "build/html-offline/#{name}")
          end
        end
      end

      if include_default_css && !File.exist?("build/html/style.css")
        offline = false
        File.write("build/html/style.css", ERB.new(Snaptoken::DefaultTemplates::CSS).result(binding))
      end
      if include_default_css && !File.exist?("build/html-offline/style.css")
        offline = true
        File.write("build/html-offline/style.css", ERB.new(Snaptoken::DefaultTemplates::CSS).result(binding))
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
