class Snaptoken::DiffTransformers::BaseTransformer
  def initialize(options = {})
    @options = options
  end

  def transform(diff)
    raise NotImplementedError
  end
end
