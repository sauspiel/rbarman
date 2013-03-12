# @author Holger Amann <holger@sauspiel.de
module RBarman

  # An array of Backup
  class Backups < Array

    # Initializes a new Array of Backup
    # @param [Array,Backups] other appends all backups from another array
    def initialize(other=nil)
      self.concat(other) if !other.nil? and other.is_a? Array
    end

    # Instructs the underlying (barman) command to get all backups for a specific server
    # @param [String] server server name
    # @param [Hash] opts options for creating {Backups}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles}
    # @return [Backups] an array of Backup
    def self.all(server, opts={})
      cmd = CliCommand.new
      return Backups.new(cmd.backups(server, nil, opts))
    end

    # Get the latest (newest) backup of all backups in the array
    # @return [Backup] the latest backup
    def latest
      self.sort_by { |d| Time.parse(d.id) }.reverse.first
    end

    # Get the oldest backup of all backups in the array
    # @return [Backup] the oldest backup
    def oldest
      self.sort_by { |d| Time.parse(d.id) }.first
    end
  end
end
