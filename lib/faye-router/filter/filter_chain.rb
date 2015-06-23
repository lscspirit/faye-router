module FayeRouter
  module Filter
    class FilterChain < Array
      # Executes filters in the FilterChain under the object context for
      # the specified type and action.
      # Execution will stop if any of the filter sets the message['error'] field
      def run_filters(context, type, action)
        self.send(type == :before ? :each : :reverse_each) do |filter|
          return false unless context.message['error'].nil?
          filter.run(context) if filter.should_apply? type, action
        end

        true
      end
    end
  end
end