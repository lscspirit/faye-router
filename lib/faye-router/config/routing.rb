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
          if cached_match.has_key? r.pattern
          else

          end
          matched = if cached_match.has_key? r.pattern
                      cached_match[r.pattern]
                    else
                      cached_match[r.pattern] = r.match_channel channel
                    end

          next if matched.nil?

          # check channel matcher
          if r.exec_matcher?(message, request)
            # convert matches to route_params hash
            params = Hash[matched.names.map { |n| [n.to_sym, matched[n]] }]
            return r, params
          end
        end

        return @default, Hash.new
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