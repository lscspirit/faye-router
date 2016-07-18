require 'faye'
require 'logger'
require 'thin'

require 'faye-router'

require File.expand_path('../channel_controller', __FILE__)

Faye.logger = Logger.new(STDOUT)
Faye.logger.level = Logger::INFO

Faye::WebSocket.load_adapter 'thin'

class EventMatcher < FayeRouter::RouteMatcher
  def initialize(event)
    @event = event
  end

  def match(message, request)
    message['data'] && message['data']['event'] == @event
  end
end

router = FayeRouter::Router.new
router.routes do
  publish '/channel_1', controller: 'ChannelController', action: :channel_1

  channel '/channel_2', controller: 'ChannelController' do
    publish match: EventMatcher.new('event_one'), action: :channel_2_event_one
    publish match: EventMatcher.new('event_two'), action: :channel_2_event_two
    publish match: EventMatcher.new('event_three'), allow: :block
  end

  publish '/channel_3/:single_param/:rest_params*', controller: 'ChannelController', action: :route_params

  subscribe '/channel_1', controller: 'ChannelController', action: :subscription
  subscribe '*', allow: :block

  default allow: :pass
end

faye_server = Faye::RackAdapter.new :mount => '/pubsub', :timeout => 25
faye_server.add_extension(router)

map '/html' do
  run Rack::File.new File.expand_path('../', __FILE__)
end

run faye_server