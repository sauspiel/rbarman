module RBarman
  class WalFiles < Array
    def initialize(other=nil)
      self.concat(other) if !other.nil? and other.is_a? Array
    end

    def self.by_id(server, backup_id)
      cmd = CliCommand.new
      return WalFiles.new(cmd.wal_files(server, backup_id))
    end
  end
end
