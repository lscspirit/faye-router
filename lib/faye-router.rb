require 'faye-router/version'
require 'faye-router/route_matcher'

module FayeRouter
  ROOT = File.expand_path(File.dirname(__FILE__))

  autoload :Router,     File.join(ROOT, 'faye-router', 'router')
  autoload :Controller, File.join(ROOT, 'faye-router', 'controller')
end
