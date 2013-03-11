# @auther Holger Amann <holger@sauspiel.de>
module RBarman

  # An Array of WalFile
  class WalFiles < Array

    # Initializes a new Array of WalFile
    # @param [Array,WalFiles] other appends all wal files from another array
    def initialize(other=nil)
      self.concat(other) if !other.nil? and other.is_a? Array
    end

    # Instructs the underlying (barman) command to get all wal files for a specific backup id
    # @param [String] server server name
    # @param [String] backup_id id of the backup
    # @return [WalFiles] an array of WalFile
    def self.by_id(server, backup_id)
      cmd = CliCommand.new
      return WalFiles.new(cmd.wal_files(server, backup_id))
    end
  end
end
