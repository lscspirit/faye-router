require 'faye-router/config/route'

module FayeRouter
  module Config
    class Routing
      def initialize
        @routes   = []
        @default  = false
        @matchers = {
          # builtin matchers
          subscribe:   -> { message['channel'] === '/meta/subscribe' },
          unsubscribe: -> { message['channel'] === '/meta/unsubscribe' },
          event:       -> (event) { message['data'] && message['data']['event'] == event }
        }
      end

      def channel(pattern, options, &block)
        ch_routing = ChannelRouting.new(@routes, @matchers, pattern, options)
        ch_routing.instance_eval &block if block_given?
      end

      def publish(pattern, options = {})
        r = Route.new pattern, options[:controller], options[:action], @matchers[options[:matcher]], options[:matcher_args]
        @routes << r
      end

      def subscribe(pattern, options = {})
        r = Route.new pattern, options[:controller], options[:action], @matchers[:subscribe]
        @routes << r
      end

      def unsubscribe(pattern, options = {})
        r = Route.new pattern, options[:controller], options[:action], @matchers[:unsubscribe]
        @routes << r
      end

      def default(action, options = {})
        case action
          when :block
            @default = false
          when :pass
            @default = true
          when :route
            @default = Route.new '/*', options[:controller], options[:action], @matchers[options[:matcher]], options[:matcher_args]
        end
      end

      def matcher(name, proc)
        raise ArgumentError, "matcher '#{name}' already exists" if @matchers.include? name.to_sym
        raise ArgumentError, 'matcher must be a Proc' unless proc.is_a? Proc
        @matchers[name.to_sym] = proc
      end

      def route(channel, message, request)
        cached_match = {}

        @routes.each do |r|
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
      def initialize(routes, matchers, pattern, options)
        @routes   = routes
        @matchers = matchers
        @pattern  = pattern
        @options  = options || {}
      end

      def publish(options = {})
        opts = @options.merge(options)
        r = Route.new @pattern, opts[:controller], opts[:action], @matchers[opts[:matcher]], opts[:matcher_args]
        @routes << r
      end

      def subscribe(options = {})
        opts = @options.merge(options)
        r = Route.new @pattern, opts[:controller], opts[:action], @matchers[:subscribe]
        @routes << r
      end

      def unsubscribe(options = {})
        opts = @options.merge(options)
        r = Route.new @pattern, opts[:controller], opts[:action], @matchers[:unsubscribe]
        @routes << r
      end
    end
  end
end