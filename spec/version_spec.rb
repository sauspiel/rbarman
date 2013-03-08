require 'spec_helper'

describe RBarman do
  it 'should return a version string' do
    RBarman::VERSION.should_not == ""
  end
end
