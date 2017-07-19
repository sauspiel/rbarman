require 'time'

# @author Holger Amann <holger@sauspiel.de>
module RBarman

  class InvalidWalFileNameError < RuntimeError
  end

  # Represents a wal file
  class WalFile

    # @overload timeline
    #   @return [String, nil] timeline part of the wal file
    # @overload timeline=
    #   Timeline part of the wal file
    #   @param [#to_s] timeline the timeline part
    #   @raise [ArgumentError] if timeline length != 8
    attr_reader :timeline 

    # @overload xlog 
    #   @return [String, nil] xlog part of the wal file
    # @overload xlog=
    #   xlog part of the wal file
    #   @param [#to_s] xlog the xlog part 
    #   @raise [ArgumentError] if xlog length != 8
    attr_reader :xlog

    # @overload segment
    #   @return [String, nil] segment part of the wal file
    # @overload segment=
    #   segment part of the wal file
    #   @param [#to_s] segment the segment part 
    #   @raise [ArgumentError] if segment length != 8
    attr_reader :segment

    # @overload created
    #   @return [Time, nil] time when wal file has been created
    # @overload created=
    #   Time when wal file has been created
    #   @param [Time,Numeric,String] created the time
    attr_reader :created

    # @overload compression
    #   @return [Symbol, nil] compression type of wal file, `:none`, `:gzip`, `:bzip2`, `:custom`
    # @overload compression=
    #   Compression type of wal file
    #   @param [Symbol] compression compression type
    #   @raise [ArgumentError] if compression is not one of `:none`, `:gzip`, `:bzip2`, `:custom`
    attr_reader :compression


    # @overload size
    #   @return [Integer, nil] size of wal file (in bytes)
    # @overload size=
    #   Size of wal file (in bytes)
    #   @param [#to_i] size size of wal file (in bytes)
    attr_reader :size

    # Creates a new instance of {WalFile}
    def initialize
    end

    def to_s
      "#{timeline}#{xlog}#{segment}"
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
        compression != :pygzip and
        compression != :pybzip2 and
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

    # Creates a new WalFile from the given argument
    # @param [String, WalFile] name the wal file name
    # @return [WalFile] the created WalFile
    # @raise [InvalidWalFileNameError] if name is a string and string's length isn't exactly 24 chars or
    #   name could not be splitted in 3 parts (timeline|xlog|segment)
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

    # Checks if other is equal to self by comparing timeline, xlog and segment
    # @param [String, WalFile] other other wal file
    # @return [Boolean] if other is equal to self
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

