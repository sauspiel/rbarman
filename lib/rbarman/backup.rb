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

    # @return [true, false] if the backup has been deleted
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

    # @return [true,false] if the wal file is already added to the backup
    # @param [String, WalFile] wal_file the wal file
    def wal_file_already_added?(wal_file)
      return false if @wal_files.nil?
      return @wal_files.include?(WalFile.parse(wal_file))
    end


    # @return [true, false] if id is a valid backup id
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

    # Instructs the underlying (barman) command to create a new backup.
    # @param [String] server server name for which a backup should be created
    # @return [Backup] a new backup object with wal files
    def self.create(server)
      cmd = CliCommand.new
      cmd.create(server)
      backups = Backups.all(server, false)
      return Backup.by_id(server, backups.latest.id, true)
    end

    # Get a specific backup
    # @param [String] server server name
    # @param [String] backup_id id of the backup
    # @param [true,false] with_wal_files if wal files should be included
    # @return [Backup] the backup
    def self.by_id(server, backup_id, with_wal_files=true)
      cmd = CliCommand.new
      return cmd.backup(server, backup_id, with_wal_files)
    end
  end
end
