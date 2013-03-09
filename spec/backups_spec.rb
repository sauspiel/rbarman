require 'spec_helper'

include RBarman

describe Backups do
  before :each do
    @backups = Backups.new
  end

  describe "#new" do
    it 'should be an instance of a Backups object' do
      @backups.should be_an_instance_of Backups
    end

    it 'should append elements from other backups' do
      b2 = Array.new
      b2 << Backup.new.tap { |b| b.id = "20130304T080002" }
      @backups = Backups.new(b2)
      expect(@backups.count).to eq(1)

      b2 = Backups.new
      b2 << Backup.new.tap { |b| b.id = "20130304T080002" }
      @backups = Backups.new(b2)
      expect(@backups.count).to eq(1)
    end
  end

  describe "latest" do
    it 'should return the latest backup' do
      @backups << Backup.new.tap { |b| b.id = "20130304T080002" }
      @backups << Backup.new.tap { |b| b.id = "20130303T081002" }
      @backups << Backup.new.tap { |b| b.id = "20130305T130002" }
      expect(@backups.latest.id).to eq("20130305T130002")
    end
    it 'should return the oldest backup' do
      @backups << Backup.new.tap { |b| b.id = "20130304T080002" }
      @backups << Backup.new.tap { |b| b.id = "20130303T081002" }
      @backups << Backup.new.tap { |b| b.id = "20130305T130002" }
      expect(@backups.oldest.id).to eq("20130303T081002")
    end

  end
end
