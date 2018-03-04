module Snaptoken::DiffTransformers
end

require 'snaptoken/diff_transformers/base_transformer'

require 'snaptoken/diff_transformers/fold_sections'
require 'snaptoken/diff_transformers/omit_adjacent_removals'
require 'snaptoken/diff_transformers/trim_blank_lines'

