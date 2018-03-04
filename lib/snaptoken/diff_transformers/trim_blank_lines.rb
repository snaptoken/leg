class Snaptoken::DiffTransformers::TrimBlankLines < Snaptoken::DiffTransformers::BaseTransformer
  def transform(diff)
    diff.clone
  end
end
