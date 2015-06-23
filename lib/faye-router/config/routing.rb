require 'faye-router/config/route'

module FayeRouter
  module Config
    class Routing
      def initialize
        @routes   = []
        @default  = Route.new :all, '*', allow: :block
      end

      def channel(pattern, options, &block)
        ch_routing = ChannelRouting.new(@routes, pattern, options)
        ch_routing.instance_eval &block if block_given?
      end

      def publish(pattern, options = {})
        r = Route.new :publish, pattern, options
        @routes << r
      end

      def subscribe(pattern, options = {})
        r = Route.new :subscribe, pattern, options
        @routes << r
      end

      def unsubscribe(pattern, options = {})
        r = Route.new :unsubscribe, pattern, options
        @routes << r
      end

      def default(options = {})
        @default = Route.new :all, '*', options
      end

      def route(type, channel, message, request)
        cached_match = {}

        @routes.each do |r|
          next unless type == :all || type == r.type

          # match channel with current route
          matched = cached_match[r.pattern]
          matched = cached_match[r.pattern] = r.channel_matches? channel if matched.nil?

          next if matched === false

          # check channel matcher
          return r if r.exec_matcher?(message, request)
        end

        @default
      end
    end

    class ChannelRouting
      def initialize(routes, pattern, options)
        @routes   = routes
        @pattern  = pattern
        @options  = options || {}
      end

      def publish(options = {})
        opts = @options.merge(options)
        r = Route.new :publish, @pattern, opts
        @routes << r
      end

      def subscribe(options = {})
        opts = @options.merge(options)
        r = Route.new :subscribe, @pattern, opts
        @routes << r
      end

      def unsubscribe(options = {})
        opts = @options.merge(options)
        r = Route.new :unsubscribe, @pattern, opts
        @routes << r
      end
    end
  end
end