module Leg
  module DiffTransformers
    class SyntaxHighlight < BaseTransformer
      class HTMLLineByLine < Rouge::Formatter
        def initialize(formatter)
          @formatter = formatter
        end

        def stream(tokens, &b)
          token_lines(tokens) do |line|
            line.each do |tok, val|
              yield @formatter.span(tok, val)
            end
            yield "\n"
          end
        end
      end

      SYNTAX_HIGHLIGHTER = HTMLLineByLine.new(Rouge::Formatters::HTML.new)

      def transform(diff)
        new_diff = diff.clone
        code = new_diff.lines.map(&:source).join("\n") + "\n"
        lexer = Rouge::Lexer.guess(filename: new_diff.filename, source: code)
        SYNTAX_HIGHLIGHTER.format(lexer.lex(code)).lines.each.with_index do |line_hl, idx|
          new_diff.lines[idx].source = line_hl
        end
        new_diff
      end
    end
  end
end
