class Snaptoken::DiffTransformers::OmitAdjacentRemovals < Snaptoken::DiffTransformers::BaseTransformer
  def transform(diff)
    diff.clone
  end
end
