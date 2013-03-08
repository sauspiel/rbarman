module RBarman
  class Backups < Array
    def initialize(other=nil)
      self.concat(other) if !other.nil? and other.is_a? Backups
    end

    def self.all(server, with_wal_files=true)
      cmd = CliCommand.new
      return Backups.new(cmd.backups(server, with_wal_files))
    end

    def latest
      self.sort_by { |d| Time.parse(d.id) }.reverse.first
    end

    def oldest
      self.sort_by { |d| Time.parse(d.id) }.first
    end
  end
end
