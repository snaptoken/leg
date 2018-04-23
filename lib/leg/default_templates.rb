module Leg
  module DefaultTemplates
    PAGE = {}
    STEP = {}

    PAGE["html"] = <<~TEMPLATE
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
        </body>
      </html>
    TEMPLATE

    STEP["html"] = <<~TEMPLATE
      <div class="step">
        <div class="step-number">
          <%= number %>
        </div>

        <% for diff in diffs %>
          <% diff = Leg::DiffTransformers::SyntaxHighlight.new.transform(diff) %>
          <div class="diff">
            <div class="diff-header">
              <div class="diff-summary">
                <%= markdown(summary) %>
              </div>
              <div class="diff-filename">
                <%= diff.filename %>
              </div>
            </div>
            <div class="diff-code">
              <table>
              <% for line in diff.lines %>
                <tr>
                  <td class="line-number">
                    <%= line.line_number %>
                  </td>
                  <td class="line <%= diff.is_new_file ? :unchanged : line.type %>">\\
                    <% if line.type == :folded %>\\
                      <%= line.source.gsub('<span class="err">…</span>', '…') %>\\
                    <% else %>\\
                      <%= line.source %>\\
                    <% end %>\\
                  </td>
                </tr>
              <% end %>
              </table>
            </div>
          </div>
        <% end %>
      </div>
    TEMPLATE

    PAGE["md"] = <<~TEMPLATE
      <%= content %>
    TEMPLATE

    STEP["md"] = <<~TEMPLATE
      ## <%= number %>. <%= summary %>

      <% for diff in diffs %>\\
      ```diff
       // <%= diff.filename %>
      <% for line in diff.lines %>\\
      <%= { added: '+', removed: '-', unchanged: ' ', folded: '@' }[line.type] + line.source %>
      <% end %>\\
      ```
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

      .step {
        margin-top: 18px;
      }

      .step-number {
        position: absolute;
        margin-top: -6px;
        margin-left: -148px;
        font-size: 48px;
        font-family: Helvetica, sans-serif;
        line-height: 130%;
        width: 128px;
        text-align: right;
      }

      .diff {
        border: 1px solid #ede7e3;
        border-radius: 3px;
      }

      .diff .diff-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 7px 10px;
        background-color: #fafbfc;
        border-bottom: 1px solid #ede7e3;
        font-size: 16px;
      }

      .diff .diff-summary {
        color: #666;
        font-size: 18px;
      }

      .diff .diff-summary p {
        margin-top: 0;
      }

      .diff .diff-filename {
        color: #666;
        font-weight: bold;
      }

      .diff table {
        width: 100%;
        border-spacing: 0;
        border-collapse: collapse;
      }

      .diff tr {
        height: 20px;
        line-height: 20px;
        padding: 0 5px;
        background-color: #fff;
        font-family: monospace;
        font-size: 14px;
      }

      .diff td.line-number {
        width: 1%;
        min-width: 55px;
        text-align: right;
        padding-right: 15px;
        background-color: #fafbfc;
        color: #ccc;
      }

      .diff td.line {
        white-space: pre;
        position: relative;
        background-color: inherit;
        padding-left: 5px;
      }

      .diff td.line.folded {
        background-color: #eef;
        opacity: 0.5;
      }

      .diff td.line.added {
        background-color: #ffd;
        text-decoration: none;
      }

      .diff td.line.removed {
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

        .diff .diff-code {
          overflow-x: scroll;
        }

        .diff .table {
          width: 700px;
        }
      }

      <%= syntax_highlighting_css ".line" %>
    TEMPLATE
  end
end
