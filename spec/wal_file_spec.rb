require 'spec_helper'

include RBarman

describe WalFile do

  before :each do
    @wal_file = WalFile.new
  end

  describe "#new" do
    it 'should be an instance of a WalFile object' do
      @wal_file.should be_an_instance_of WalFile
    end
  end

  describe "timeline=" do
    it 'should raise ArgumentError if arg is not of size 8' do
      lambda { @wal_file.timeline = "123" }.should raise_error(ArgumentError)
      lambda { @wal_file.timeline = "123456789" }.should raise_error(ArgumentError)
    end

    it 'should assign a timeline' do
      arg = '12345678'
      @wal_file.timeline = arg
      @wal_file.timeline.should == arg
    end
  end

  describe "xlog=" do
    it 'should raise ArgumentError if arg is not of size 8' do
      lambda { @wal_file.xlog = "123" }.should raise_error(ArgumentError)
      lambda { @wal_file.xlog = "123456789" }.should raise_error(ArgumentError)
    end

    it 'should assign a xlog' do
      arg = '12345678'
      @wal_file.xlog = arg
      @wal_file.xlog.should == arg
    end
  end

  describe "segment=" do
    it 'should raise ArgumentError if arg is not of size 8' do
      lambda { @wal_file.segment = "123" }.should raise_error(ArgumentError)
      lambda { @wal_file.segment = "123456789" }.should raise_error(ArgumentError)
    end

    it 'should assign a segment' do
      arg = '12345678'
      @wal_file.segment = arg
      @wal_file.segment.should == arg
    end
  end

  describe "created=" do
    it 'should assign created from float' do
      arg = 1362668936.0
      @wal_file.created = arg
      expect(@wal_file.created).to eq(Time.at(1362668936)) 
    end

    it 'should assign created from int' do
      arg = 1362668936
      @wal_file.created = arg
      expect(@wal_file.created).to eq(Time.at(1362668936)) 
    end

    it 'should assign created from string' do
      t = Time.now
      @wal_file.created = t.to_s
      expect(@wal_file.created.to_i).to eq(t.to_i)
    end

    it 'should assign created from time' do
      t = Time.now
      @wal_file.created = t
      expect(@wal_file.created).to eq(t)
    end
  end

  describe "size=" do
    it 'should assign a size' do
      a = 123
      @wal_file.size = a
      expect(@wal_file.size).to eq(a)
    end
  end

  describe "compression=" do
    it 'should raise ArgumentError if arg not like :gzip, :bzip2, :none or :custom' do
      expect { @wal_file.compression = 'started' }.to raise_error(ArgumentError)
      expect { @wal_file.compression = :some }.to raise_error(ArgumentError)
    end

    it 'should accept args like :empty, :started, :done or :failed' do
      compressions = [ :gzip, :bzip2, :none, :custom]
      compressions.each do |c|
        @wal_file.compression = c
        expect(@wal_file.compression).to eq(c)
      end
    end
  end


  describe ".parse" do
    it 'should raise InvalidWalFileName exception' do
      lambda { WalFile.parse("").should raise_error }.should raise_error(InvalidWalFileNameError)
      lambda { WalFile.parse("12345678").should raise_error }.should raise_error(InvalidWalFileNameError)
      lambda { WalFile.parse("1234567812345678123456789").should raise_error }.should raise_error(InvalidWalFileNameError)
    end

    it 'should return a valid WalFile object' do
      w = WalFile.parse("0000000100000599000000D5")
      w.timeline.should == "00000001"
      w.xlog.should == "00000599"
      w.segment.should == "000000D5"
    end

    it 'should return same WalFile if arg is a WalFile' do
      w = WalFile.parse("0000000100000599000000D5")
      w1 = WalFile.parse(w)
      expect(w.xlog).to eq(w1.xlog)
      expect(w.timeline).to eq(w1.timeline)
      expect(w.segment).to eq(w1.segment)
    end
  end

  describe "==(other)" do
    it 'should return true if other wal file is equal' do
       w1 = WalFile.parse("0000000100000599000000D6")
       w2 = WalFile.parse("0000000100000599000000D6")
       (w1 == w2).should == true
    end

    it 'should return false if other wal file does is not equal' do
       w1 = WalFile.parse("0000000100000599000000D5")
       w2 = WalFile.parse("0000000100000599000000D6")
       (w1 == w2).should == false
    end

    it 'should handle strings' do
      w1 = WalFile.parse("0000000100000599000000D6")
      expect(w1).to eq("0000000100000599000000D6")
      expect(w1).to_not eq("0000000100000599000000D5")
    end
  end

end
