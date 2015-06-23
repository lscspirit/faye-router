require 'faye-router/config/route'
require 'faye-router/config/routing'

require 'faye-router/bayeux/error'

module FayeRouter
  class Router
    include Faye::Logging
    include FayeRouter::Bayeux::Error

    def initialize
      @routing = FayeRouter::Config::Routing.new
    end

    def incoming(message, request, callback)
      begin
        route_message message, request
      rescue => ex
        # in case of runtime error, log the stack trace and return an '_unknown_error' error to the client
        fatal ex.message + "\n  " + ex.backtrace.join("\n  ")
        message['error'] = bayeux_error :server_error, 'Unknown error', 'faye-router'
      end

      callback.call message
    end

    #
    # Configuration
    #

    def routes(&block)
      @routing.instance_eval &block if block_given?
    end

    private

    def route_message(message, request)
      type, channel = extract_type_and_channel message

      # let all meta messages (except subscribe and unsubscribe) pass through
      unless type == :meta
        route = @routing.route type, channel, message, request

        if route.allow == :block
          # if there is no matching route AND this is not a /meta message, then return an invalid channel error
          message['error'] = bayeux_error :channel_unknown, 'No route found for channel', 'faye-router', channel
        elsif route.allow == :route
          ctrl = spawn_controller route.controller, type, channel, message, request
          ctrl.perform_action route.action
        end
      end
    end

    def extract_type_and_channel(message)
      case message['channel']
        when '/meta/subscribe'
          return :subscribe, message['subscription']
        when '/meta/unsubscribe'
          return :unsubscribe, message['subscription']
        when /^\/meta\/.+$/
          return :meta, nil
        else
          return :publish, message['channel']
      end
    end

    def spawn_controller(controller, type, channel, message, request)
      klass = Kernel.const_get(controller)
      raise "#{controller} is not a FayeRouter::Controller" unless klass <= FayeRouter::Controller

      klass.new type, channel, message, request
    end
  end
end