# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'faye-router/version'

Gem::Specification.new do |spec|
  spec.name          = 'faye-router'
  spec.version       = FayeRouter::VERSION
  spec.authors       = ['Derrick Yeung']
  spec.email         = ['lscspirit@hotmail.com']

  spec.summary       = 'A simple Faye adapter for routing messages (in Rails style)'
  spec.description   = 'This adapter allows you to route message to different controllers based upon the message channel and content.'
  spec.homepage      = 'https://github.com/lscspirit/faye-router'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = nil
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|examples)/}) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faye', '~> 1.1'

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'thin'
end
