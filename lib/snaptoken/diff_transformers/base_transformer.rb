class Snaptoken::DiffTransformers::BaseTransformer
  def transform(diff)
    raise NotImplementedError
  end
end
