require "rouge/plugins/redcarpet"

class Snaptoken::Commands::Doc < Snaptoken::Commands::BaseCommand
  def self.name
    "doc"
  end

  def self.summary
    "Render files in doc/ into an HTML book."
  end

  def self.usage
    "[-c] [-z] [-q]"
  end

  def setopts!(o)
    o.on("-c", "--cached", "Use cached diff HTML (much faster)") do |c|
      @opts[:cached] = c
    end

    o.on("-z", "--zip", "Also create a .zip archive in doc/") do |z|
      @opts[:zip] = z
    end

    o.on("-q", "--quiet", "Don't output progress") do |q|
      @opts[:quiet] = q
    end
  end

  def run
    needs! :config, :doc
    if @opts[:cached]
      needs! :cached_diffs
    else
      needs! :repo
      #sync_args = @opts[:quiet] ? ["--quiet"] : []
      #Snaptoken::Commands::Sync.new(sync_args, @config).run
      @steps = nil # XXX just in case @steps were already cached
    end

    FileUtils.cd(File.join(@config[:path], "doc")) do
      FileUtils.rm_rf("html_out")
      FileUtils.rm_rf("html_offline")
      FileUtils.mkdir("html_out")
      FileUtils.mkdir("html_offline")

      copy_static_files
      write_css
      write_html_files(prerender_diffs)
      create_archive if @opts[:zip]
    end
  end

  class HTMLRouge < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  private

  def copy_static_files
    Dir["html_in/*"].each do |f|
      name = File.basename(f)
      unless %w(template.html template_index.html style.css fonts.css).include? name
        FileUtils.cp_r(f, "html_out/#{name}") unless name == "fonts"
        FileUtils.cp_r(f, "html_offline/#{name}")
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
      theme_css.gsub!("font-weight: bold;", "font-weight: #{@config[:bold_weight]};")
    end

    css = File.read("html_in/style.css")
    css << theme_css

    offline_css = css.sub(/^@import .+$/, File.read("html_in/fonts.css"))

    File.write("html_out/style.css", css)
    File.write("html_offline/style.css", offline_css)
  end

  def prerender_diffs
    if @opts[:cached]
      return Marshal.load(File.read("../.cached-diffs"))
    end

    diffs = {}
    FileUtils.cd(@config[:path]) do
      repo = Rugged::Repository.new("repo")
      empty_tree = Rugged::Tree.empty(repo)

      walker = Rugged::Walker.new(repo)
      walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
      walker.push(repo.branches.find { |b| b.name == "master" }.target)

      step_num = 1
      walker.each do |commit|
        commit_message = commit.message.strip
        next if commit_message == "-"
        summary = commit_message.lines.first.strip
        step_name = summary.split(' ').first # temporarararary
        last_commit = commit.parents.first
        diff = (last_commit || empty_tree).diff(commit, context_lines: 100_000, ignore_whitespace_change: true)
        patches = diff.each_patch.reject { |p| p.delta.new_file[:path] == ".dummyleg" }
        next if patches.empty?

        patch = patches.map(&:to_s).join("\n")

        print "\r\e[K[repo/ -> .cached-diffs] #{step_name}" unless @opts[:quiet]

        diff = Snaptoken::Diff.new(@config, patch, step_num, step_name)
        diffs[step_name] = diff.html.values.join("\n")
        step_num += 1
      end
      print "\n" unless @opts[:quiet]
    end
    File.write("../.cached-diffs", Marshal.dump(diffs))
    diffs
  end

  def write_html_files(diffs)
    html_template = File.read("html_in/template.html")

    index = ""
    html_renderer = HTMLRouge.new(with_toc_data: true)
    markdown = Redcarpet::Markdown.new(html_renderer, fenced_code_blocks: true)
    pages = Dir["*.md"].sort.map { |f| f.sub(/\.md$/, '') }
    pages.delete "00.index"
    pages.each.with_index do |page, idx|
      print "\r\e[K[doc/ -> doc/html_out/] #{page}.html" unless @opts[:quiet]
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
      content.gsub!(/<\/code>&lsquo;/) { "</code>&rsquo;" }
      content.gsub!(/^\s*<h([23456]) id="([^"]+)">(.+)<\/h\d>$/) {
        "<h#{$1} id=\"#{$2}\"><a href=\"##{$2}\">#{$3}</a></h#{$1}>"
      }
      content.gsub!(/<p>{{([\w-]+)}}<\/p>/) { diffs[$1] }

      html = html_template.dup
      html.gsub!("{{title}}") { "#{idx+1}. #{title} | #{@config[:title]}" }
      html.gsub!("{{prev_link}}") { prev_link }
      html.gsub!("{{next_link}}") { next_link }
      html.gsub!("{{version}}") { @config[:version] }
      html.gsub!("{{content}}") { content }

      File.write(File.join("html_out", "#{page}.html"), html)
      File.write(File.join("html_offline", "#{page}.html"), html)
    end
    print "\n" unless @opts[:quiet]

    content = markdown.render(File.read("00.index.md"))
    content = Redcarpet::Render::SmartyPants.render(content)
    content.gsub!(/<p>{{toc}}<\/p>/) { "<ol>#{index}</ol>" }

    if File.exist?("html_in/template_index.html")
      html = File.read("html_in/template_index.html")
    else
      html = html_template.dup
    end

    html.gsub!("{{title}}") { @config[:title] }
    html.gsub!("{{prev_link}}") { "<a href='#'></a>" }
    html.gsub!("{{next_link}}") { "<a href='#{pages.first}.html'>next &rarr;</a>" }
    html.gsub!("{{version}}") { @config[:version] }
    html.gsub!("{{content}}") { content }

    File.write("html_out/index.html", html)
    File.write("html_offline/index.html", html)
  end

  def create_archive
    name = "#{@config[:name]}-tutorial-#{@config[:version]}"

    FileUtils.mv("html_offline", name)

    `zip -r #{name}.zip #{name}`

    FileUtils.mv(name, "html_offline")
  end
end

