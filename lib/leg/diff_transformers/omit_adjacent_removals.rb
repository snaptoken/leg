class Leg::DiffTransformers::OmitAdjacentRemovals < Leg::DiffTransformers::BaseTransformer
  def transform(diff)
    new_diff = diff.clone

    removed_lines = []
    saw_added_line = false
    new_diff.lines.each.with_index do |line, idx|
      case line.type
      when :unchanged, :folded
        if saw_added_line
          removed_lines.each do |removed_idx|
            new_diff.lines[removed_idx] = nil
          end
        end

        removed_lines = []
        saw_added_line = false
      when :added
        saw_added_line = true
      when :removed
        removed_lines << idx
      end
    end

    new_diff.lines.compact!
    new_diff
  end
end
