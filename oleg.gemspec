Gem::Specification.new do |s|
  s.name        = 'oleg'
  s.version     = '0.6.0'
  s.license     = 'MIT'
  s.summary     = 'tools for .leg files'
  s.author      = 'Jeremy Ruten'
  s.email       = 'jeremy.ruten@gmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'https://github.com/yjerem/leg'
  s.executables << 'leg'

  s.add_runtime_dependency 'rugged', '0.25.1.1'
end

