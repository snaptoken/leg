module Leg
  module DiffTransformers
    class TrimBlankLines < BaseTransformer
      def transform(diff)
        new_diff = diff.clone_empty
        diff.lines.each.with_index do |line, idx|
          line = line.clone
          if line.blank? && [:added, :removed].include?(line.type)
            prev_line = idx > 0 ? diff.lines[idx - 1] : nil
            next_line = idx < diff.lines.length - 1 ? diff.lines[idx + 1] : nil

            prev_changed = prev_line && [:added, :removed].include?(prev_line.type)
            next_changed = next_line && [:added, :removed].include?(next_line.type)

            if !prev_changed || !next_changed
              line.type = :unchanged
            end
          end
          new_diff.lines << line
        end
        new_diff
      end
    end
  end
end
