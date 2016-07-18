require 'faye-router/filter/filter'
require 'faye-router/filter/filter_chain'

require 'faye-router/bayeux/error'

module FayeRouter
  class Controller
    include Faye::Logging
    include FayeRouter::Bayeux::Error

    # Properties
    attr_reader :message_type, :channel, :params, :message, :request

    class << self; attr_accessor :filter_chain end
    self.filter_chain = FayeRouter::Filter::FilterChain.new

    # copies the filter chain in each subclass so that each will
    # have its own instance and would not overwrites each other chain
    def self.inherited(subclass)
      subclass.filter_chain = self.filter_chain.dup
    end

    # Constructor
    def initialize(message_type, channel, route_params, msg, request)
      @message_type = message_type
      @channel = channel
      @params  = route_params
      @message = msg
      @request = request
    end

    # Execution
    def perform_action(action)
      action_sym = action.to_sym
      if self.respond_to? action_sym
        execute_with_filters(action_sym) { self.send action_sym }
      else
        raise NoMethodError, "'#{action}' not found in #{self.class.name}"
      end
    end

    private

    #
    # Filter Logic
    #
    def self.before_action(filter_method, options = {})
      self.filter_chain << FayeRouter::Filter::BeforeFilter.new(filter_method, options)
    end

    def self.after_action(filter_method, options = {})
      self.filter_chain << FayeRouter::Filter::AfterFilter.new(filter_method, options)
    end

    def execute_with_filters(action)
      if self.class.filter_chain.run_filters self, :before, action
        # only continues if before filters are successfully executed
        yield if block_given?   # executes main action

        # executes after filters, no filter will run if the message['error'] field is already set
        self.class.filter_chain.run_filters self, :after, action
      end
    end
  end
end