module Leg::Markdown
  class HTMLRouge < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet
  end

  HTML_RENDERER = HTMLRouge.new(with_toc_data: true)
  MARKDOWN_RENDERER = Redcarpet::Markdown.new(HTML_RENDERER, fenced_code_blocks: true)

  def self.render(source)
    html = MARKDOWN_RENDERER.render(source)
    html = Redcarpet::Render::SmartyPants.render(html)
    html.gsub!(/<\/code>&lsquo;/) { "</code>&rsquo;" }
    html.gsub!(/^\s*<h([23456]) id="([^"]+)">(.+)<\/h\d>$/) {
      "<h#{$1} id=\"#{$2}\"><a href=\"##{$2}\">#{$3}</a></h#{$1}>"
    }
    html
  end
end
