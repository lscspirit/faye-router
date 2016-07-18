module FayeRouter
  module Config
    class Route
      attr_reader :pattern, :type, :controller, :action, :allow

      def initialize(type, pattern, options = {})
        @type         = type
        @pattern      = pattern
        @regex        = Route::parse_to_regex pattern
        @controller   = options[:controller]
        @action       = options[:action]
        @matcher      = options[:match]
        @allow        = options[:allow] || :route

        # Validations

        if pattern.nil? || pattern.empty?
          raise ArgumentError, 'Channel pattern cannot be nil ro empty'
        end

        unless [:block, :pass, :route].include? @allow
          raise ArgumentError, 'Invalid :allow value. Must be one of :block, :pass, :route'
        end

        unless @matcher.nil? || @matcher.is_a?(FayeRouter::RouteMatcher)
          raise ArgumentError, 'Matcher must be a RouteMatcher'
        end

        if @allow == :route
          raise ArgumentError, 'A valid route must have a controller and a corresponding action' if @controller.nil? || @action.nil?
          raise ArgumentError, 'Action must either be a string or a symbol' unless @action.is_a?(Symbol) || @action.is_a?(String)
        end
      end

      def channel_matches?(channel)
        !!(channel =~ @regex)
      end

      def exec_matcher?(message, request)
        return true if @matcher.nil?
        @matcher.match message, request
      end

      private

      def self.parse_to_regex(pattern)
        escaped = Regexp.escape(pattern).gsub('\*','.*?')
        Regexp.new "^#{escaped}$", Regexp::IGNORECASE
      end
    end
  end
end