# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aggregator/version'

Gem::Specification.new do |spec|
  spec.name          = "aggregator"
  spec.version       = Aggregator::VERSION
  spec.authors       = ["Joao Carlos"]
  spec.email         = ["joao@adtile.me"]
  spec.summary       = %q{Aggregate items on a separate thread.}
  spec.description   = %q{Define aggregators that run on a separate thread so that you can do more, faster.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", ">= 5.0.0"
  spec.add_development_dependency "rubysl", "~> 2.0" if RUBY_ENGINE == "rbx"
end
