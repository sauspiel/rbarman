require 'spec_helper'

describe WalFiles do
  before :each do
    @wal_files = WalFiles.new
  end

  describe "#new" do
    it 'should be an instance of a WalFiles object' do
      expect(@wal_files).to be_an_instance_of WalFiles
    end

    it 'should append elements from other walfiles' do
      w2 = Array.new
      w2 << WalFile.parse("0000000100000599000000D5")
      w2 << WalFile.parse("0000000100000599000000D6")
      @wal_files = WalFiles.new(w2)
      expect(@wal_files.count).to eq(2)

      w2 = WalFiles.new
      w2 << WalFile.parse("0000000100000599000000D5")
      w2 << WalFile.parse("0000000100000599000000D6")

      @wal_files = WalFiles.new(w2)
      expect(@wal_files.count).to eq(2)

    end

    describe ".by_id" do
      it 'should return a valid WalFiles object' do
        w = Array.new
        w << WalFile.parse("0000000100000599000000D5")
        w << WalFile.parse("0000000100000599000000D6")
        CliCommand.any_instance.stub(:binary=)
        CliCommand.any_instance.stub(:barman_home=)
        CliCommand.any_instance.stub(:wal_files).and_return(w)
        CliCommand.any_instance.should_receive(:wal_files).once.with('test', '123')
        @wal_files = WalFiles.by_id('test', '123')
        expect(@wal_files.count).to eq(2)
        expect(@wal_files[0]).to eq("0000000100000599000000D5")
      end
    end
  end
end
