# @author Holger Amann <holger@sauspiel.de
module RBarman

  # An array of backups
  class Backups < Array

    # Initializes a new backup array
    # @param [Array,Backups] other appends all backups from another array
    def initialize(other=nil)
      self.concat(other) if !other.nil? and other.is_a? Array
    end

    # Instructs the underlying (barman) command to get all backups for a specific server
    # @param [String] server server name
    # @param [true,false] with_wal_files including wal files
    # @return [Backups] an array of backups
    def self.all(server, with_wal_files=true)
      cmd = CliCommand.new
      return Backups.new(cmd.backups(server, with_wal_files))
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
