require 'spec_helper'


describe "SQL Notification" do
  it "should call" do
    Statify.statsd.should_receive(:measure).with(any_args()).at_least(:once)
    DummyModel.create(:foo => 'bar', :bar => 'foo')
  end
end