require 'mixlib/shellout'

# @author Holger Amann <holger@sauspiel.de>
module RBarman

  # Wrapper for the barman command line tool
  class CliCommand

    # @overload binary
    #   @return [String] path to the barman binary
    # @overload binary=
    #   Path to the barman binary
    #   @param [String] path path to the binary
    #   @raise [ArgumentError] if path doesn't exist or path doesn't end with 'barman'
    attr_reader :binary 

    # @overload barman_home
    #   @return [String] base path where barman stores its backups
    # @overload barman_home=
    #   Path to the base directory of barman's backups
    #   @param [String] path path to the base directory
    #   @raise [ArgumentError] if path doesn't exist
    attr_reader :barman_home

    # Creates a new instance of CliCommand
    # @param [String] path_to_binary see {#binary}. If nil, it will be initialized from {Configuration}
    # @param [String] path_to_barman_home see {#barman_home}. If nil, it will be initialized from {Configuration}
    def initialize(path_to_binary=nil, path_to_barman_home=nil)
      self.binary=path_to_binary || Configuration.instance.binary
      self.barman_home=path_to_barman_home || Configuration.instance.barman_home
    end

    def binary=(path)
      raise(ArgumentError, "binary doesn't exist") if !File.exists?(path)
      raise(ArgumentError, "binary isn't called \'barman\'") if File.basename(path) != 'barman'
      @binary = path
    end

    def barman_home=(path)
      raise(ArgumentError, "path doesn't exist") if !File.exists?(path)
      @barman_home = path
    end

    # Instructs barman to get information about a specific backup
    # @param [String] server server name
    # @param [String] backup_id id of the backup
    # @param [Hash] opts options for creating a {Backup}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles} in each {Backup}
    # @return [Backup] a new {Backup} object
    # @raise [ArgumentError] if backup_id is nil
    def backup(server, backup_id, opts = {})
      raise(ArgumentError, "backup id must not be nil!") if backup_id.nil?
      opts[:backup_id] = backup_id
      return backups(server, opts)[0]
    end

    # Instructs barman to get information about backups
    # @param [String] server server name
    # @param [String] backup_id when given, only information about this backup id will be retrieved
    # @param [Hash] opts options for creating {Backups}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles} in each {Backup}
    # @option opts [String] :backup_id retrieve just one {Backup} specified by this backup id
    # @return [Backups] an array of {Backup}
    def backups(server, opts = {})
      list = run_barman_command("list-backup #{server}")
      list = list.grep(/#{opts[:backup_id]}/) if !opts[:backup_id].nil?

      backups = parse_backup_list(list)
      backups.each do |backup|
        parse_backup_info_file(backup)
        if opts[:with_wal_files]
          wals = wal_files(backup.server, backup.id)
          wals.each { |w| backup.add_wal_file(w) }
        end
      end
      return backups
    end

    # Instructs barman to get information about a server
    # @param [String] name name of the server
    # @param [Hash] opts options for creating {Server}
    # @option opts [Boolean] :with_backups whether to include {Backups} in {Server}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles} in each {Backup}
    # @return [Server] a new {Server}
    def server(name, opts = {})
      lines = run_barman_command("show-server #{name}")
      server = parse_show_server_lines(name, lines)
      lines = run_barman_command("check #{name}")
      parse_check_lines(server, lines)
      server.backups = backups(server.name, opts) if opts[:with_backups]
      return server
    end

    # Instructs barman to get information about all servers
    # @param [Hash] opts options for creating {Servers}
    # @option opts [Boolean] :with_backups whether to include {Backups}
    # @option opts [Boolean] :with_wal_files whether to include {WalFiles}
    # @return [Servers] an array of {Server}
    def servers(opts = {})
      result = Servers.new
      lines = run_barman_command("list-server")
      server_names = parse_list_server_lines(lines)
      server_names.each do |name|
        result << server(name, opts)
      end
      return result
    end

    # Instructs barman to list all wal files for a specific backup id
    # @param [String] server server name
    # @param [String] backup_id id of the backup
    # @return [WalFiles] an array of {WalFile}
    # @raise [RuntimeError] if wal file duplicates are found in xlog.db
    # @raise [RuntimeError] if barman lists a wal file but no information could be found in xlog.db
    def wal_files(server, backup_id)
      lines = run_barman_command("list-files --target wal #{server} #{backup_id}")
      wal_files = parse_wal_files_list(lines)
      xlog_db_lines = file_content("#{@barman_home}/#{server}/wals/xlog.db")
      wal_files.each do |w| 
        wal = "#{w.timeline}#{w.xlog}#{w.segment}"
        lines = xlog_db_lines.grep(/^#{wal}\t.+/)
        raise(RuntimeError, "Found more than one wal file entry in xlog.db for #{wal}") if lines.count > 1
        raise(RuntimeError, "Could not find any entry for #{wal} in xlog.db") if lines.count == 0
        wal_file_info_from_xlog_db_line(w, lines[0])
      end
      return wal_files
    end


    # Parses lines reported by barman's `list-server`
    # @param [Array<String>] lines an array of lines from output of barman's `list-server` cmd
    # @return [Array<String>] an array of server names
    def parse_list_server_lines(lines)
      result = Array.new
      lines.each do |l|
        result << l.split("-")[0].strip
      end
      return result
    end


    # Creates a {Server} object by parsing lines reported by barman's `show-server`
    # @param [String] server name of the server
    # @param [Array<String>] lines an array of lines from output of barman's `show-server` cmd
    # @return [Server] a new {Server} object
    def parse_show_server_lines(server, lines)
      s = Server.new(server)
      lines.each do |l|
        key, value = l.gsub("\t","").split(": ")
        case key.chomp
        when "active"
          s.active = value.to_bool
        when "ssh_command"
          s.ssh_cmd = value
        when "conninfo"
          s.conn_info = value
        when "backup_directory"
          s.backup_dir = value
        when "basebackups_directory"
          s.base_backups_dir = value
        when "wals_directory"
          s.wals_dir = value
        end
      end
      return s
    end

    # Parses lines reported by barman's `check` and assigns according values
    # @param [Server] server the server
    # @param [Array<String>] lines an array of lines from output of barman's `check` cmd
    # @raise [ArgumentError] if server is nil
    def parse_check_lines(server, lines)
      raise(ArgumentError, 'arg server not of type Server') if !server.is_a? Server
      lines.each do |l|
        key, value = l.gsub("\t","").split(": ")
        case key.chomp
        when "ssh"
          server.ssh_check_ok = value == "OK" ? true : false
        when "PostgreSQL"
          server.pg_conn_ok = value == "OK" ? true : false
        end
      end
    end

    # Creates a {WalFiles} object by parsing lines reported by barman
    # @param [Array<String>] lines an array of lines like '/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BC'
    # @return [WalFiles] the {WalFiles}
    def parse_wal_files_list(lines)
      wal_files = Array.new
      lines.each do |line|
        wal_files << WalFile.parse(line.split("/").last)
      end
      return wal_files
    end

    # Creates an array of {Backup} by parsing lines reported by barman
    # @param [Array<String>] lines an array of lines like 'test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB'
    # @return [Array<Backup>] an array of {Backup}
    def parse_backup_list(lines)
      result = Array.new
      lines.each do |l|
        match = l.match(/^(.+)\s(\d+T\d+)/)
        b = Backup.new
        b.server = match[1]
        b.id = match[2]

        status_match = l.match(/.+(FAILED|STARTED)/)
        status_match.nil? ? b.status = :done : b.status = status_match[1].downcase.to_sym
        
        if b.status == :done
          sizematch = l.match(/.+Size:\s(.+)\s(.+)\s-.+Size:\s(.+)\s(.+)/)
          b.size = CliCommand.size_in_bytes(sizematch[1].to_f, sizematch[2])
          b.wal_file_size = CliCommand.size_in_bytes(sizematch[3].to_f, sizematch[4])
        end
        result << b
      end
      return result
    end

    # Assigns various values to a {Backup} by parsing the according "backup.info"
    # @param [Backup] backup the backup
    # @return [void]
    # @raise [ArgumentError] if backup is not of type {Backup}
    # @raise [ArgumentError] if backup.id is not set
    # @raise [ArgumentError] if backup.server is not set
    def parse_backup_info_file(backup)
      raise(ArgumentError, "arg not of type Backup") if !backup.is_a? Backup
      raise(ArgumentError, "Backup.id not set") if backup.id.nil?
      raise(ArgumentError, "Backup.server not set") if backup.server.nil?
      backup_info = file_content("#{barman_home}/#{backup.server}/base/#{backup.id}/backup.info")
      backup_info.each do |l|
        key, value = l.split("=")
        case key
        when "begin_time"
          backup.backup_start = value
        when "end_time"
          backup.backup_end = value
        when "status"
          backup.status = value.downcase.to_sym
        when "size"
          backup.size = value.to_i
        when "timeline"
          backup.timeline = value.to_i
        when "begin_wal"
          backup.begin_wal = WalFile.parse(value)
        when "end_wal"
          backup.end_wal = WalFile.parse(value)
        when "pgdata"
          backup.pgdata = value
        end
      end
    end

    # Assigns size, created and compression values to a {WalFile} by parsing a line from xlog.db
    # @param [WalFile] wal_file the wal file
    # @param [String] line a string like '00000001000005A9000000BC\\t4684503\t1360568429.0\\tbzip2'
    # @return [void]
    def wal_file_info_from_xlog_db_line(wal_file, line)
      splitted = line.split("\t")
      wal_file.size = splitted[1]
      wal_file.created = splitted[2].to_i
      wal_file.compression = splitted[3].downcase.to_sym
    end

    # Converts the size according to the unit to bytes
    # @param [Numeric] size the size
    # @param [String] unit the unit, like `B`, `KiB`, `MiB`, `GiB` or `TiB`
    # @return [Integer] the size in bytes
    # @raise [ArgumentError] if unit is not one of B|KiB|MiB|GiB|TiB
    # @example
    #   CliCommand.size_in_bytes(2048, 'B') #=> 2048
    #   CliCommand.size_in_bytes(2048, 'MiB') #=> 2048 * 1024 ** 2
    def self.size_in_bytes(size, unit)
      raise(ArgumentError, "unit not one of B|KiB|MiB|GiB|TiB") if !unit.match(/(B|KiB|MiB|GiB|TiB)/)
      size_b = 0
      case unit 
      when "B"
        size_b = size
      when "KiB"
        size_b = size * 1024
      when "MiB"
        size_b = size * 1024 ** 2
      when "GiB"
        size_b = size * 1024 ** 3
      when "TiB"
        size_b = size * 1024 ** 4 
      end
      return size_b.to_i
    end

    # Instructs barman to delete a specific backup
    # @param [String] server server name
    # @param [String] backup_id id of the backup
    # @return [void]
    def delete(server, backup_id)
      run_barman_command("delete #{server} #{backup_id}")
    end

    # Instructs barman to create a backup
    # @param [String] server server name
    # @return [void]
    def create(server)
      run_barman_command("backup #{server}")
    end

    private
    def run_barman_command(args)
      sh = Mixlib::ShellOut.new("#{@binary} #{args}")

      # TODO timeout should be configurable
      sh.timeout = 43200 # 12h

      sh.run_command
      sh.error!
      return sh.stdout.split("\n")
    end

    def file_content(path)
      return File.readlines(path).map { |l| l.chomp }
    end
  end
end
