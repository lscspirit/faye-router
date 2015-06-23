require 'faye'
require 'logger'
require 'thin'

require 'faye-router'

require File.expand_path('../channel_controller', __FILE__)

Faye.logger = Logger.new(STDOUT)
Faye.logger.level = Logger::INFO

Faye::WebSocket.load_adapter 'thin'

router = FayeRouter::Router.new
router.routes do
  publish '/channel_1', controller: 'ChannelController', action: :channel_1

  channel '/channel_2', controller: 'ChannelController' do
    publish matcher: :event, matcher_args: 'event_one', action: :channel_2_event_one
    publish matcher: :event, matcher_args: 'event_two', action: :channel_2_event_two
  end

  subscribe '/*', controller: 'ChannelController', action: :subscription

  default :block
end

faye_server = Faye::RackAdapter.new :mount => '/pubsub', :timeout => 25
faye_server.add_extension(router)

map '/html' do
  run Rack::File.new File.expand_path('../', __FILE__)
end

run faye_server