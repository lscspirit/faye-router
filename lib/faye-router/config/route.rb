module FayeRouter
  module Config
    class Route
      attr_reader :pattern, :controller, :action

      def initialize(pattern, controller, action, matcher = nil, matcher_args = nil)
        @pattern      = pattern
        @regex        = Route::parse_to_regex pattern
        @controller   = controller
        @action       = action
        @matcher      = matcher
        @matcher_args = matcher_args
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