lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quick_service/version'

Gem::Specification.new do |spec|
  spec.name          = 'quick_service'
  spec.version       = QuickService::VERSION
  spec.authors       = ['Federico Aldunate']
  spec.email         = ['federico.aldunatec@gmail.com']

  spec.summary       = 'A tiny Ruby gem for the Service Object pattern.'
  spec.description   = 'QuickService provides a small, dependency-light base ' \
                       'class for building service objects with a consistent ' \
                       'success/failure result interface.'
  spec.homepage      = 'https://github.com/federicoaldunate/quick_service'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/federicoaldunate/quick_service/'
    spec.metadata['changelog_uri'] = 'https://github.com/federicoaldunate/quick_service/releases'
    spec.metadata['bug_tracker_uri'] = 'https://github.com/federicoaldunate/quick_service/issues'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['lib/**/*.rb', 'README.md', 'CHANGELOG.md', 'LICENSE.txt']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 5.2'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'debug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
end
