# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'empirical/client/version'

Gem::Specification.new do |spec|
  spec.name          = "empirical-client"
  spec.version       = Empirical::Client::VERSION
  spec.authors       = ["Empirical.org", "James Cox"]
  spec.email         = ["developers@quill.org"]
  spec.summary       = "Quill.org API Client Wrapper"
  spec.homepage      = "https://github.com/empirical-org/empirical-client"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'faraday_middleware'
  spec.add_runtime_dependency 'oauth2', '>= 0'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'hashie'
  spec.add_runtime_dependency 'patron'

  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "fuubar", '~> 2.0.0.rc1'
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-shell"
  spec.add_development_dependency "terminal-notifier-guard"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-remote"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "awesome_print"
end
