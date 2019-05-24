Gem::Specification.new do |s|
  s.name     = 'permessage_deflate'
  s.version  = '0.1.4'
  s.summary  = 'Per-message DEFLATE compression extension for WebSocket connections'
  s.author   = 'James Coglan'
  s.email    = 'jcoglan@gmail.com'
  s.homepage = 'https://github.com/faye/permessage-deflate-ruby'
  s.license  = 'Apache-2.0'

  s.extra_rdoc_files = %w[README.md]
  s.rdoc_options     = %w[--main README.md --markup markdown]
  s.require_paths    = %w[lib]

  s.files = %w[CHANGELOG.md LICENSE.md README.md] + Dir.glob('lib/**/*.rb')

  s.add_development_dependency 'rspec'
end
