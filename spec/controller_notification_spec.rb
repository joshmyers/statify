require 'spec_helper'

describe DummyController, :type => :controller do
  # Note the controller is empty so we are assured that the statsd this is calling is indeed the controller ones
  it "should receive measure" do
    Statify.statsd.should_receive(:measure).with(any_args()).at_least(3).times
    get :index
  end
end