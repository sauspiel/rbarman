require 'singleton'

module RBarman
  class Configuration
    include Singleton 

    def initialize(data={})
      @data = {}
      update!(data)
      basic_configuration
    end

    def update!(data)
      data.each do |key, value|
        self[key] = value
      end
    end

    def [](key)
      @data[key.to_sym]
    end

    def []=(key, value)
      if value.class == Hash
        @data[key.to_sym] = Config.new(value)
      else
        @data[key.to_sym] = value
      end
    end

    def method_missing(sym, *args)
      if sym.to_s =~ /(.+)=$/
        self[$1] = args.first
      else
        self[sym]
      end
    end

    def basic_configuration
      b_path = `which barman`.chomp
      self[:binary] = b_path.empty? ? '/usr/bin/barman' : b_path
      self[:barman_home] = ENV['HOME']
    end

  end
end
