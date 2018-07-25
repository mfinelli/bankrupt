lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bankrupt/version"

Gem::Specification.new do |spec|
  spec.name          = "bankrupt"
  spec.version       = Bankrupt::VERSION
  spec.authors       = ["Mario Finelli"]
  spec.email         = ["mario@finel.li"]

  spec.summary       = %q{A sinatra helper to load assets in development and production.}
  spec.description   = %q{This gem loads files from disk locally and from a CDN in production.}
  spec.homepage      = "https://github.com/mfinelli/bankrupt"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ["lib"]

  spec.add_dependency 'slim', '~> 3.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rspec", "~> 3.7"
end
