require 'time'

module RBarman

  class InvalidBackupIdError < RuntimeError
  end

  class Backup
    attr_accessor :server 
    attr_reader :id, :backup_start, :backup_end, :status, :wal_files, :size, :wal_file_size, :begin_wal, :end_wal, :timeline, :pgdata, :deleted

    def initialize
      @deleted = false
    end

    def id=(id)
      raise InvalidBackupIdError if !Backup.backup_id_valid?(id)
      @id = id 
    end

    def backup_start=(start)
      @backup_start = Time.parse(start)
    end

    def backup_end=(b_end)
      @backup_end = Time.parse(b_end)
    end

    def status=(status)
      if status != :empty and
        status != :started and
        status != :done and
        status != :failed
        raise(ArgumentError,"only :empty, :started, :done or :failed allowed!")
      end

      @status = status
    end

    def wal_files=(wal_files)
      raise(ArgumentError, "argument not of type array") if !wal_files.is_a? Array
      @wal_files = wal_files
    end

    def size=(size)
      @size = size.to_i
    end

    def begin_wal=(wal_file)
      @begin_wal = WalFile.parse(wal_file)
    end

    def end_wal=(wal_file)
      @end_wal = WalFile.parse(wal_file)
    end


    def wal_file_size=(size)
      @wal_file_size = size.to_i
    end

    def timeline=(i)
      raise(ArgumentError, "timeline should be > 0") if i.to_i == 0
      @timeline = i.to_i
    end

    def pgdata=(path)
      raise(ArgumentError, "path is empty") if path == ""
      @pgdata = path
    end

    def add_wal_file(wal_file)
      @wal_files = Array.new if @wal_files.nil?
      @wal_files << WalFile.parse(wal_file)
    end

    def wal_file_already_added?(wal_file)
      return false if @wal_files.nil?
      return @wal_files.include?(WalFile.parse(wal_file))
    end


    def self.backup_id_valid?(id)
      return false if id.nil?
      return !id.match(/\d{8,8}T\d{6,6}/).nil?
    end

    def delete
      cmd = CliCommand.new
      cmd.delete(@server, @backup_id)
      @deleted = true
    end

    def self.create(server)
      cmd = CliCommand.new
      cmd.create(server)
      backups = Backups.all(server, false)
      return Backup.by_id(server, backups.latest.id, true)
    end

    def self.by_id(server, backup_id, with_wal_files=true)
      cmd = CliCommand.new
      return cmd.backup(server, backup_id, with_wal_files)
    end
  end
end
