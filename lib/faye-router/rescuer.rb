module FayeRouter
  module Rescuer
    class Handler
      # Creates an instance of rescue handler
      #
      # @example
      #   FayeRouter::Rescuer::Handler.new ArgumentError, NoMethodError, with: :error_handler
      #
      #   def error_handler(ex)
      #     logger.error ex.message
      #   end
      #
      # @example
      #   FayeRouter::Rescuer::Handler.new ArgumentError, NoMethodError do |ex|
      #     logger.error ex.message
      #   end
      def initialize(*ex_klasses, &block)
        @options = self.class.extract_options!(ex_klasses)
        @klasses = []

        @action = if @options.has_key?(:with)
                    @options[:with]
                  elsif block_given?
                    block
                  else
                    raise ArgumentError, 'No action is given. Must provide a :with option or a block'
                  end

        ex_klasses.each do |klass|
          if klass.is_a?(Class) && klass <= Exception
            @klasses << klass.name
          elsif klass.is_a?(String)
            @klasses << klass
          else
            raise ArgumentError, "#{klass} must be an Exception or a String"
          end
        end
      end

      # Whether this handler is applicable for the provided Exception
      #
      # @param ex [Exception] the exception to check against
      #
      # @return [Boolean] true if this handler is applicable
      def applicable?(ex)
        @klasses.any? do |klass_name|
          klass = Kernel.const_get klass_name
          ex.is_a? klass
        end
      end

      # Executes the resuce handler
      #
      # @param context [Object] context within which the handler should be executed
      # @param error [Exception] exception to rescued from
      def rescue_error(context, error)
        if @action.is_a?(Proc)
          context.instance_exec error, &@action
        else
          context.send @action.to_sym, error
        end
      end

      private

      def self.extract_options!(klasses_args)
        if klasses_args.last.is_a?(Hash)
          klasses_args.pop
        else
          {}
        end
      end
    end

    class Chain < Array
      # Rescues exception with handlers defined in this chain
      #
      # @param context [Object] current execution context
      # @param error [Exception] exception raised
      #
      # @return [Boolean] true if the error is handled by this chain; false otherwise
      def rescue_error(context, error)
        # search for handlers in reverse order
        # (i.e. the later the definition of the handler, the higher the priority)
        reverse_each do |handler|
          if handler.applicable?(error)
            handler.rescue_error context, error
            return true     # terminates once the error is handled
          end
        end

        # no applicable handler found. return false
        false
      end
    end
  end
end