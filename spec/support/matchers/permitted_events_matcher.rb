require 'rspec/expectations'

RSpec::Matchers.define :have_no_permitted_events do
  match do |controller|
    controller.instance_variable_get(:@permitted_events) == []
  end
  failure_message do |actual|
    "expected permitted_events to be empty, was #{actual.instance_variable_get(:@permitted_events).inspect}"
  end
end


RSpec::Matchers.define :have_permitted_events do |*args|
  match do |controller|
    controller.instance_variable_get(:@permitted_events) == args
  end
  failure_message do |actual|
    "expected permitted_events to be #{controller.instance_variable_get(:@permitted_events).inspect}, was #{actual.instance_variable_get(:@permitted_events).inspect}"
  end
end


RSpec::Matchers.define :have_permitted_events_including do |*args|
  match do |controller|
    (args - controller.instance_variable_get(:@permitted_events)).empty?
  end
  failure_message do |actual|
    "expected permitted_events to include #{args.inspect}, was #{actual.instance_variable_get(:@permitted_events).inspect}"
  end
end



RSpec::Matchers.define :have_nil_permitted_events do
  match do |controller|
    controller.instance_variable_get(:@permitted_events).nil?
  end
  failure_message do |actual|
    "expected permitted_events to be nil, was #{actual.instance_variable_get(:@permitted_events.inspect)}"
  end
end