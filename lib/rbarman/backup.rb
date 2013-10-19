require 'time'

# @author Holger Amann <holger@sauspiel.de>
module RBarman

  class InvalidBackupIdError < RuntimeError
  end


  # Represents a barman Backup
  class Backup

    # @return [String, nil] name of the server to which the backup belongs. 
    attr_accessor :server 

    # @overload id
    #   @return [String, nil] id (like '20130304T080002') which identifies 
    #     the backup and is unique among all backups of a server. 
    # @overload id=
    #   Id of the backup
    #   @param [#to_s] id id of the backup
    #   @raise [InvalidBackupIdError] if the id is not valid
    #   @see backup_id_valid?
    attr_reader :id

    # @overload backup_start
    #   @return [Time, nil] time when the backup started. 
    # @overload backup_start=
    #   Start of the backup 
    #   @param [#to_s] start time when the backup started
    attr_reader :backup_start

    # @overload backup_end
    #   @return [Time, nil] time when the backup stopped. 
    # @overload backup_end=
    #   End of the backup
    #   @param [#to_s] b_end time when the backup stopped
    attr_reader :backup_end 

    # @overload status
    #   @return [Symbol, nil] status of the backup, `:empty`, `:started`, `:done` or `:failed`
    # @overload status=
    #   Status of the backup
    #   @param [Symbol] status status of the backup 
    #   @raise [ArgumentError] if status is not one of `:empty`, `:started`, `:done` or `:failed`
    attr_reader :status

    # @overload wal_files
    #   @return [WalFiles, nil] All wal files
    # @overload wal_files=
    #   All wal files
    #   @param [Array, WalFiles] wal_files all wal files
    #   @raise [ArgumentError] if argument is not an Array
    attr_reader :wal_files

    # @overload size
    #   @return [Integer, nil] size of data (in bytes)
    # @overload size=
    #   Size of data (in bytes)
    #   @param [#to_i] size size (in bytes 
    attr_reader :size 

    # @overload wal_file_size
    #   @return [Integer, nil] size of wal files (in bytes)
    # @overload wal_file_size=
    #   Size of wal files (in bytes)
    #   @param [#to_i] size size of wal files (in bytes)
    attr_reader :wal_file_size

    # @overload begin_wal
    #   @return [WalFile, nil] first wal file after backup started
    # @overload begin_wal=
    #   First wal file after backup started
    #   @param [String,WalFile] wal_file the wal file
    attr_reader :begin_wal

    # @overload end_wal
    #   @return [WalFile, nil] last wal file after backup stopped
    # @overload end_wal=
    #   Last wal file after backup stopped
    #   @param [String,WalFile] wal_file the wal file
    attr_reader :end_wal

    # @overload timeline
    #   @return [Integer, nil] timeline of the backup. 
    # @overload timeline=
    #   Timeline of the backup
    #   @param [Integer] i timeline of the backup
    #   @raise [ArgumentError] if timeline == 0
    attr_reader :timeline

    # @overload pgdata
    #   @return [String, nil] server's data directory
    # @overload pgdata=
    #   Server's data directory
    #   @param [String] path path to directory
    #   @raise [ArgumentError] if path is empty
    attr_reader :pgdata

    # @return [Boolean] if the backup has been deleted
    attr_reader :deleted

    def initialize
      @deleted = false
    end

    def id=(id)
      raise InvalidBackupIdError if !Backup.backup_id_valid?(id.to_s)
      @id = id.to_s
    end

    def backup_start=(start)
      @backup_start = Time.parse(start.to_s)
    end

    def backup_end=(b_end)
      @backup_end = Time.parse(b_end.to_s)
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

    # Adds a wal file to the backup
    # @param [String, WalFile] wal_file the wal file
    # @return [void]
    def add_wal_file(wal_file)
      @wal_files = WalFiles.new if @wal_files.nil?
      @wal_files << WalFile.parse(wal_file)
    end

    # @return [Boolean] if the wal file is already added to the backup
    # @param [String, WalFile] wal_file the wal file
    def wal_file_already_added?(wal_file)
      return false if @wal_files.nil?
      return @wal_files.include?(WalFile.parse(wal_file))
    end


    # @return [Boolean] if id is a valid backup id
    # @param [#to_s] id the backup id
    # @example Check if a backup id is valid
    #   Backup.backup_id_valid?("20130304T080002") #=> true
    #   Backup.backup_id_valid?("213") #=> false
    def self.backup_id_valid?(id)
      return false if id.nil?
      return !id.to_s.match(/\d{8,8}T\d{6,6}/).nil?
    end

    # Instructs the underlying (barman) command to delete the backup and sets its flag {#deleted} to true
    def delete
      cmd = CliCommand.new
      cmd.delete(@server, @id)
      @deleted = true
    end

    # @return [Array, String] a range of available xlog entries
    def xlog_range
      start_xlog = @begin_wal.xlog
      end_xlog = @wal_files.last.xlog
      xlog_range = Array.new
      (start_xlog.to_i(16)..end_xlog.to_i(16)).to_a.each do |i|
        xlog_range << i.to_s(16).upcase
      end
      xlog_range
    end

    # @return [WalFiles] all wal files which should exist in this backup
    def needed_wal_files
      needed = Array.new
      xlog_range.each do |xlog|
        start = 0
        if @begin_wal.xlog == xlog.to_s.rjust(8,'0')
          start = @begin_wal.segment.to_i(16)
        end
        (start..254).each do |seg|
          w = WalFile.new
          w.timeline = @begin_wal.timeline
          w.xlog = xlog.rjust(8,'0')
          w.segment = seg.to_s(16).rjust(8,'0').upcase
          needed << w
          break if w == @wal_files.last
        end
      end
      WalFiles.new(needed)
    end

    # @return [WalFiles] all wal files which don't exist in this backup
    def missing_wal_files
      missing = Array.new
      needed_wal_files.each do |needed|
        existing = @wal_files.select { |f| f == needed }.first
        missing << existing unless existing 
      end
      WalFiles.new(missing)
    end

    # Instructs the underlying (barman) command to recover this backup
    # @param [String] path the path to which the backup should be restored
    # @param [Hash] opts options passed as arguments to barman recover cmd
    # @option opts [String] :remote_ssh_cmd the ssh command to be used for remote recovery
    # @option opts [String, Time] :target_time the timestamp as recovery target
    # @option opts [String] :target_xid the transaction ID as recovery target
    # @option opts [Boolean] :exclusive whether to stop immediately before or after the recovery target
    # @return [void]
    # @note when :remote_ssh_cmd is passed in options, 'path' is the path on the remote host, otherwise local
    # @since 0.0.3
    # @example
    #   backup.recover('/var/lib/postgresql/9.2/main', { :remote_ssh_cmd => 'ssh postgres@10.20.20.2' })
    def recover(path, opts = {})
      cmd = CliCommand.new
      cmd.recover(@server, @id, path, opts)
    end

    # Instructs the underlying (barman) command to create a new backup.
    # @param [String] server server name for which a backup should be created
    # @return [Backup] a new backup object with wal files
    def self.create(server)
      cmd = CliCommand.new
      cmd.create(server)
      backups = Backups.all(server, { :with_wal_files => false })
      return Backup.by_id(server, backups.latest.id, { :with_wal_files => true })
    end

    # Get a specific backup
    # @param [String] server server name
    # @param [String] backup_id id of the backup
    # @param [Hash] opts options for creating a {Backup}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles} in {Backup}
    # @return [Backup] the backup
    def self.by_id(server, backup_id, opts = {})
      cmd = CliCommand.new
      return cmd.backup(server, backup_id, opts)
    end
  end
end
