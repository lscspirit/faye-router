module FayeRouter
  module Filter
    class Base
      attr_reader :filter_method, :options

      #
      # Constructor
      #
      def initialize(filter_method, options)
        @filter_method = filter_method
        @options = options
      end

      #
      # Filter Matching
      #
      def before?
        false
      end

      def after?
        false
      end

      def should_apply? type, action
        type_matched?(type) && action_matched?(action)
      end

      def type_matched? type
        case type
          when :before
            before?
          when :after
            after?
          else
            false
        end
      end

      def action_matched? action
        return false if options[:except] && [options[:except]].flatten.include?(action)
        return false if options[:only] && ![options[:only]].flatten.include?(action)

        true
      end

      #
      # Execution
      #
      def run(context)
        context.send self.filter_method
      end
    end

    class BeforeFilter < Base
      def before?
        true
      end

      def after?
        false
      end
    end

    class AfterFilter < Base
      def before?
        false
      end

      def after?
        true
      end
    end
  end
end