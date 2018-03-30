lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "leg/version"

Gem::Specification.new do |spec|
  spec.name          = "leg"
  spec.version       = Leg::VERSION
  spec.authors       = ["Jeremy Ruten"]
  spec.email         = ["jeremy.ruten@gmail.com"]

  spec.summary       = %q{Tools for creating step-by-step programming tutorials}
  #spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "https://github.com/yjerem/leg"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rugged', '0.25.1.1'
  spec.add_runtime_dependency 'redcarpet', '3.4.0'
  spec.add_runtime_dependency 'rouge', '2.0.7'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
end
