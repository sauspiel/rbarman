require 'spec_helper'

include RBarman

describe Configuration do
  before :each do
    @config = Configuration
  end

  it "should set binary on initialize" do
    expect(@config.instance.binary).to eq('/usr/bin/barman')
  end

  it "should set barman_home on initialize" do
    expect(@config.instance.barman_home).to eq(ENV['HOME'])
  end

  it "should set the barman binary" do
    @config.instance.binary = '/bin/true'
    expect(@config.instance.binary).to eq('/bin/true')
  end
  
  it 'should set barman home' do
    @config.instance.barman_home = '/home/user'
    expect(@config.instance.barman_home).to eq('/home/user')
  end
end
