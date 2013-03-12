# @author Holger Amann <holger@sauspiel.de>

module RBarman

  # Represents a server for which barman should do/have backups
  class Server

    # @param [String] name name of the server
    # @return [String] name of the server
    attr_accessor :name

    # @param [Boolean] active if server is active
    # @return [Boolean] if server is active
    attr_accessor :active

    # @param [String] cmd ssh command
    # @return [String] the ssh command
    attr_accessor :ssh_cmd

    # @param [String] the connection info
    # @return [String] the connection info
    attr_accessor :conn_info

    # @param [String] path to backup directory
    # @return [String] the path to backup directory
    attr_accessor :backup_dir

    # @param [String] path to base backups directory
    # @return [String] the path to base backups directory
    attr_accessor :base_backups_dir

    # @param [String] path to wals directory
    # @return [String] the path to wals directory
    attr_accessor :wals_dir

    # @param [Boolean] if SSH connection is working
    # @return [Boolean] if SSH connection is working
    attr_accessor :ssh_check_ok

    # @param [Boolean] if PostgreSQL connection is working
    # @return [Boolean] if PostgreSQL connection is working
    attr_accessor :pg_conn_ok


    # Creates a new instance of {Server}
    def initialize(name)
      @name = name
    end

  end
end
