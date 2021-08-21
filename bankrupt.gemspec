# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bankrupt/version'

Gem::Specification.new do |spec|
  spec.name = 'bankrupt'
  spec.version = Bankrupt::VERSION
  spec.authors = ['Mario Finelli']
  spec.email = ['mario@finel.li']

  spec.summary = 'A sinatra helper to load assets locally and production.'
  spec.description = 'Load files from local disk or from a CDN in production.'
  spec.homepage = 'https://github.com/mfinelli/bankrupt'
  spec.license = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.5.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'slim', '>= 3.0', '< 5.0'
  spec.add_development_dependency 'aws-sdk-s3'
  spec.add_development_dependency 'mini_mime'
  spec.add_development_dependency 'rake'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'redcarpet'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
