# @author Holger Amann <holger@sauspiel.de>

module RBarman

  # Represents a server for which barman should do/have backups
  class Server

    # @param [String] name name of the server
    # @return [String] name of the server
    attr_accessor :name

    # @param [Boolean] active if server is active
    # @return [Boolean, nil] if server is active
    attr_accessor :active

    # @param [String] cmd ssh command
    # @return [String, nil] the ssh command
    attr_accessor :ssh_cmd

    # @param [String] the connection info
    # @return [String, nil] the connection info
    attr_accessor :conn_info

    # @param [String] path to backup directory
    # @return [String, nil] the path to backup directory
    attr_accessor :backup_dir

    # @param [String] path to base backups directory
    # @return [String, nil] the path to base backups directory
    attr_accessor :base_backups_dir

    # @param [String] path to wals directory
    # @return [String, nil] the path to wals directory
    attr_accessor :wals_dir

    # @param [Boolean] if SSH connection is working
    # @return [Boolean, nil] if SSH connection is working
    attr_accessor :ssh_check_ok

    # @param [Boolean] if PostgreSQL connection is working
    # @return [Boolean, nil] if PostgreSQL connection is working
    attr_accessor :pg_conn_ok

    # @param [Backups] server backups
    # @return [Backups, nil] server backups
    attr_accessor :backups

    # @param [String] PostgreSQL version
    # @return [String] PostgreSQL version
    attr_accessor :pg_version


    # Creates a new instance of {Server}
    def initialize(name)
      @name = name
    end

    # Instructs the underlying (barman) command to get information about a server
    # @param [String] name name of the server
    # @param [Hash] opts options for creating {Server}
    # @option opts [Boolean] :with_backups whether to include {Backups}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles} in each {Backup}
    def self.by_name(name, opts = {})
      cmd = CliCommand.new
      return cmd.server(name, opts)
    end
  end

  # An array of {Server}
  class Servers < Array
    # Initializes a new Array of {Server}
    # @param [Array, Servers] other appends all servers from another array
    def initialize(other=nil)
      self.concat(other) if !other.nil? and other.is_a? Array
    end

    # Instructs the underlying (barman) command to get all servers
    # @param [Hash] opts options for creating {Servers}
    # @option opts [Boolean] :with_backups whether to include {Backups}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles}
    # @return [Servers] an array of {Server}
    def self.all(opts={})
      cmd = CliCommand.new
      return Servers.new(cmd.servers(opts))
    end
  end
end
