require 'time'

module RBarman

  class InvalidWalFileNameError < RuntimeError
  end

  class WalFile

    attr_reader :timeline, :xlog, :segment, :created, :compression, :size

    def initialize
    end

    def timeline=(timeline)
      validate(timeline)
      @timeline = timeline
    end

    def xlog=(xlog)
      validate(xlog)
      @xlog = xlog
    end

    def segment=(segment)
      validate(segment)
      @segment = segment
    end

    def compression=(compression)
      if compression != :gzip and
        compression != :bzip2 and
        compression != :none and
        compression != :custom
        raise(ArgumentError, "only :gzip, :bzip2, :none or :custom allowed!")
      end

      @compression = compression
    end

    def size=(size)
      @size = size.to_i
    end

    def created=(created)
      @created = created if created.is_a? Time
      @created = Time.at(created.to_i) if created.is_a? Numeric
      @created = Time.parse(created) if created.is_a? String
    end

    def self.parse(name)
      raise(InvalidWalFileNameError, "name has to be exactly 24 chars") if !name.is_a? WalFile and name.to_s.size != 24 

      if name.is_a? WalFile
        wal_file = name
      else
        splitted = name.to_s.scan(/.{8}/)
        raise InvalidWalFileNameError if splitted.count != 3

        wal_file = WalFile.new
        wal_file.timeline = splitted[0]
        wal_file.xlog = splitted[1]
        wal_file.segment = splitted[2]
      end

      return wal_file
    end

    def ==(other)
      o = other
      o = WalFile.parse(other.to_s) if !other.is_a? WalFile
      return o.timeline == @timeline && o.xlog == @xlog && o.segment == @segment
    end

    private

    def validate(arg)
      raise(ArgumentError, "arg's size must be 8") if arg.to_s.size != 8
    end
  end
end

