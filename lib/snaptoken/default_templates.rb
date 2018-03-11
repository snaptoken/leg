module Snaptoken::DefaultTemplates
  PAGE = <<~TEMPLATE
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <title><%= page_number %>. <%= page_title %></title>
        <link href="style.css" rel="stylesheet">
      </head>
      <body>
        <header class="bar">
          <nav>
            <% if prev_page %>
              <a href="<%= prev_page.filename %>.html">&larr; prev</a>
            <% else %>
              <a href="#"></a>
            <% end %>

            <a href="<%= pages.first.filename %>.html">beginning</a>

            <% if next_page %>
              <a href="<%= next_page.filename %>.html">next &rarr;</a>
            <% else %>
              <a href="#"></a>
            <% end %>
          </nav>
        </header>
        <div id="container">
          <%= content %>
        </div>
        <footer class="bar">
          <nav>
            <a href="#">top of page</a>
          </nav>
        </footer>
      </body>
    </html>
  TEMPLATE

  STEP = <<~TEMPLATE
    <% for diff in diffs %>
      <div class="diff">
        <div class="diff-header">
          <div class="step-filename">
            <%= diff.filename %>
          </div>
          <div class="step-number">
            Step <%= number %>
          </div>
        </div>
        <pre class="highlight"><code>\\
          <% for line in diff.lines %>\\
            <% if line.type == :folded %>\\
              <div class="line folded">\\
                <%= line.source.gsub('<span class="err">…</span>', '…') %>\\
              </div>\\
            <% else %>\\
              <% tag = {unchanged: :div, added: :ins, removed: :del}[line.type] %>\\
              <% tag = :div if diff.is_new_file %>\\
              <<%= tag %> class="line">\\
                <%= line.source %>\\
              </<%= tag %>>\\
            <% end %>\\
          <% end %>\\
        </code></pre>
      </div>
    <% end %>
  TEMPLATE

  CSS = <<~TEMPLATE
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }

    body {
      font-family: Utopia, Georgia, Times, 'Apple Symbols', serif;
      line-height: 140%;
      color: #333;
      font-size: 18px;
    }

    #container {
      width: 700px;
      margin: 18px auto;
    }

    .bar {
      display: block;
      width: 100%;
      background-color: #ceb;
      box-shadow: 0px 0px 15px 1px #ddd;
    }

    .bar > nav {
      display: flex;
      justify-content: space-between;
      width: 700px;
      margin: 0 auto;
    }

    footer.bar > nav {
      justify-content: center;
    }

    .bar > nav > a {
      display: block;
      padding: 2px 0 4px 0;
      color: #152;
    }

    h1, h2, h3, h4, h5, h6 {
      font-family: Futura, Helvetica, Arial, sans-serif;
      color: #222;
      line-height: 100%;
      margin-top: 32px;
    }

    h2 a, h3 a, h4 a {
      color: inherit;
      text-decoration: none;
    }

    h2 a::before, h3 a::before, h4 a::before {
      content: '#';
      color: #fff;
      font-weight: normal;
      transition: color 0.15s ease;
      display: block;
      float: left;
      width: 32px;
      margin-left: -32px;
    }

    h2 a:hover::before, h3 a:hover::before, h4 a:hover::before {
      color: #ccc;
    }

    h1 {
      margin-top: 0;
      font-size: 38px;
      border-bottom: 3px solid #e7c;
      display: inline-block;
    }

    h2 {
      font-size: 26px;
    }

    p {
      margin-top: 18px;
    }

    ul, ol {
      margin-top: 18px;
      margin-left: 36px;
    }

    hr {
      border: none;
      border-bottom: 1px solid #888;
    }

    a {
      color: #26d;
    }

    code {
      font-family: monospace;
      font-size: inherit;
      white-space: nowrap;
      background-color: #eff4ea;
      padding: 1px 3px;
    }

    h1 code, h2 code, h3 code, h4 code, h5 code, h6 code {
      font-weight: normal;
    }

    kbd {
      font-family: monospace;
      border-radius: 3px;
      padding: 2px 3px;
      box-shadow: 1px 1px 1px #777;
      margin: 2px;
      font-size: 14px;
      background: #f7f7f7;
      font-weight: 500;
      color: #555;
      white-space: nowrap;
    }

    h1 kbd, h2 kbd, h3 kbd, h4 kbd, h5 kbd, h6 kbd {
      font-size: 80%;
    }

    .diff code {
      font-size: 14px;
      line-height: 20px;
      background-color: none;
      padding: 0;
      margin-bottom: 18px;
      white-space: inherit;
    }

    .diff pre {
      background-color: #fffcfa;
      padding: 5px 0;
    }

    .diff {
      border: 1px solid #ede7e3;
      border-radius: 3px;
      margin-top: 18px;
    }

    .diff .diff-header {
      display: flex;
      justify-content: space-between;
      padding: 0 5px;
      background-color: #ede7e3;
      font-size: 16px;
      color: #666;
    }

    .diff .step-number {
      font-weight: bold;
    }

    .diff .step-filename {
      font-weight: bold;
    }

    .diff .step-name {
      font-family: monospace;
      font-size: 12px;
    }

    .diff .line {
      display: block;
      height: 20px;
      padding: 0 5px;
      position: relative;
    }

    .diff .line.folded {
      background-color: #eef;
      opacity: 0.5;
    }

    .diff ins.line {
      background-color: #ffd;
      text-decoration: none;
    }

    .diff del.line {
      background-color: #fdd;
      text-decoration: line-through;
    }

    @media screen and (max-width: 700px) {
      #container {
        width: auto;
        margin: 18px 0;
        padding: 0 5px;
      }

      .bar > nav {
        width: auto;
        margin: 0;
        padding: 0 5px;
      }

      .highlight {
        overflow-x: scroll;
      }

      .diff .line {
        width: 700px;
      }
    }

    <%= syntax_highlighting_css ".highlight" %>
  TEMPLATE
end
