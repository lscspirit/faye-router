require 'faye-router/filter/filter'
require 'faye-router/filter/filter_chain'
require 'faye-router/rescuer'

require 'faye-router/bayeux/error'

module FayeRouter
  class Controller
    include Faye::Logging
    include FayeRouter::Bayeux::Error

    # Properties
    attr_reader :message_type, :channel, :params, :message, :request

    class << self;
      attr_accessor :filter_chain
      attr_accessor :rescuer_chain
    end
    self.filter_chain  = FayeRouter::Filter::FilterChain.new
    self.rescuer_chain = FayeRouter::Rescuer::Chain.new

    # copies the filter chain and rescuer chain in each subclass so that each will
    # have its own instances and would not overwrites each other's chains
    def self.inherited(subclass)
      subclass.filter_chain  = self.filter_chain.dup
      subclass.rescuer_chain = self.rescuer_chain.dup
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
        begin
          execute_with_filters(action_sym) { self.send action_sym }
        rescue Exception => ex
          # allows rescuer chain to rescue the error
          raise unless self.class.rescuer_chain.rescue_error self, ex
        end
      else
        raise NoMethodError, "'#{action}' not found in #{self.class.name}"
      end
    end

    private

    #
    # Rescuer Logic
    #

    # Registers a rescue handler for this controller
    #
    # @example
    #   rescue_from ArgumentError, NoMethodError, with: :error_handler
    #
    #   def error_handler(ex)
    #     logger.error ex.message
    #   end
    #
    # @example
    #   rescue_from ArgumentError, NoMethodError do |ex|
    #     logger.error ex.message
    #   end
    def self.rescue_from(*ex_klasses, &block)
      self.rescuer_chain << FayeRouter::Rescuer::Handler.new(*ex_klasses, &block)
    end

    #
    # Filter Logic
    #

    # Registers a before action hook
    #
    # @param filter_method [Symbol, String] method to be executed
    # @param options [Hash] hook option
    # @option options [Symbol, Array<Symbol>] :except actions for which the hook should not be executed
    # @option options [Symbol, Array<Symbol>] :only actions for which the hook should be executed
    def self.before_action(filter_method, options = {})
      self.filter_chain << FayeRouter::Filter::BeforeFilter.new(filter_method, options)
    end

    # Registers a after action hook
    #
    # @param filter_method [Symbol, String] method to be executed
    # @param options [Hash] hook option
    # @option options [Symbol, Array<Symbol>] :except actions for which the hook should not be executed
    # @option options [Symbol, Array<Symbol>] :only actions for which the hook should be executed
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