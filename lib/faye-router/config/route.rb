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
        @matcher      = options[:matcher]
        @matcher_args = options[:matcher_args]
        @allow        = options[:allow] || :route

        # Validations

        if pattern.nil? || pattern.empty?
          raise ArgumentError, 'Channel pattern cannot be nil ro empty'
        end

        unless [:block, :pass, :route].include? @allow
          raise ArgumentError, 'Invalid :allow value. Must be one of :block, :pass, :route'
        end

        unless @matcher.nil? || @matcher.is_a?(Proc)
          raise ArgumentError, 'Matcher must be a Proc'
        end

        if options.has_key?(:matcher_args) && @matcher.nil?
          raise ArgumentError, 'A matcher must be specified if :matcher_args is present'
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
        base = OpenStruct.new(message: message, request: request)
        args = @matcher_args ? [@matcher_args].flatten : nil

        args.nil? ? base.instance_exec(&@matcher) : base.instance_exec(*args, &@matcher)
      end

      private

      def self.parse_to_regex(pattern)
        escaped = Regexp.escape(pattern).gsub('\*','.*?')
        Regexp.new "^#{escaped}$", Regexp::IGNORECASE
      end
    end
  end
end