require 'singleton'

module RBarman

  # A very flexible configuration class, to be used as Singleton
  class Configuration
    include Singleton 

    # Creates a new instance of {Configuration}
    # @param [Hash] data added as configuration parameters
    def initialize(data={})
      @data = {}
      update!(data)
      basic_configuration
    end

    # Adds parameters
    # @param [Hash] data parameters to add
    # @return [void]
    def update!(data)
      data.each do |key, value|
        self[key] = value
      end
    end

    # Gives access to parameters
    # @param [String,Symbol] key the key
    # @return [Object, nil] the value
    def [](key)
      @data[key.to_sym]
    end

    # Adds a new parameter
    # @param [String] key the key
    # @param [Object] value the value
    # @return [void]
    def []=(key, value)
      if value.class == Hash
        @data[key.to_sym] = Config.new(value)
      else
        @data[key.to_sym] = value
      end
    end

    # For catching [NoMethodError] and trying to add a new parameter or returning a parameter value, based on the "missing" method name
    # @param [Symbol] sym the method name
    # @param [Array] args the arguments passed to the method.
    # @return [Object, nil, void] when method name doesn't end with an `=` operator, a parameter value will be returned (if found, otherwise nil)
    # @example
    #   Configuration.instance[:some_key] = "some_value"
    #   Configuration.instance.some_key #=> "some_value"
    #   Configuration.instance.another_key = { :a => 1 }
    #   Configuration.instance[:another_key] #=> { :a => 1}
    #   Configuration.instance[:missing] #=> nil
    def method_missing(sym, *args)
      if sym.to_s =~ /(.+)=$/
        self[$1] = args.first
      else
        self[sym]
      end
    end

    # adds `:binary` with path to barman binary as value and `:barman_home` (default $HOME) with path to barman's backup base directory as value. If `which` reports a path for barman, that path will be used, otherwise `/usr/bin/barman`
    # @return [void]
    # @example
    #  Configuration.Instance.binary #=> "/usr/bin/barman"
    #  Configuration.Instance.barman_home #=> "/var/lib/barman"
    def basic_configuration
      b_path = `which barman`.chomp
      self[:binary] = b_path.empty? ? '/usr/bin/barman' : b_path
      self[:barman_home] = ENV['HOME']
    end

  end
end
