class ChannelController < FayeRouter::Controller
  before_action :before_processing
  before_action :before_subscription, only: :subscription
  after_action  :after_processing, except: :channel_1

  def channel_1
    info "Processing message in channel 1: #{message.to_s}"
  end

  def channel_2_event_one
    info "Processing message in channel 2 event_one: #{message.to_s}"
  end

  def channel_2_event_two
    info "Processing message in channel 2 event_two: #{message.to_s}"
  end

  def subscription
    info "subscribing to #{channel}"
  end

  def route_params
    info "Params: #{params[:single_param]} - #{params[:rest_params]}"
  end

  private

  def before_processing
    info 'before processing'
  end

  def after_processing
    info 'after processing'
  end

  def before_subscription
    info 'before subscribing'
  end
end