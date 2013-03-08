# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbarman/version'

Gem::Specification.new do |spec|
  spec.name          = "rbarman"
  spec.version       = RBarman::VERSION
  spec.authors       = ["Holger Amann"]
  spec.email         = ["holger@sauspiel.de"]
  spec.description   = %q{Wrapper about 2ndQuadrant's postgresql backup tool \'barman\'}
  spec.summary       = %q{Wrapper about 2ndQuadrant's postgresql backup tool \'barman\'}
  spec.homepage      = "https://github.com/sauspiel/rbarman"
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*.rb', 'LICENSE.txt', 'README.md']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 1.3"
  spec.add_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_dependency "mixlib-shellout", "~> 1.1.0"
end
