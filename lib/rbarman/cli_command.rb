require 'mixlib/shellout'

module RBarman
  class CliCommand
    attr_reader :binary, :barman_home

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

    def backup(server, backup_id, with_wal_files=true)
      raise(ArgumentError, "backup id must not be nil!") if backup_id.nil?
      return backups(server, with_wal_files, backup_id)[0]
    end

    def backups(server, with_wal_files=true, backup_id=nil)
      list = run_barman_command("list-backup #{server}")
      list = list.grep(/#{backup_id}/) if !backup_id.nil?

      backups = parse_backup_list(list)
      backups.each do |backup|
        parse_backup_info_file(backup)
        if with_wal_files
          wals = wal_files(backup.server, backup.id)
          wals.each { |w| backup.add_wal_file(w) }
        end
      end
      return backups
    end

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

    def parse_wal_files_list(lines)
      wal_files = Array.new
      lines.each do |line|
        wal_files << WalFile.parse(line.split("/").last)
      end
      return wal_files
    end

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
          b.size = size_in_bytes(sizematch[1].to_f, sizematch[2])
          b.wal_file_size = size_in_bytes(sizematch[3].to_f, sizematch[4])
        end
        result << b
      end
      return result
    end

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

    def wal_file_info_from_xlog_db_line(wal_file, line)
      splitted = line.split("\t")
      wal_file.size = splitted[1]
      wal_file.created = splitted[2].to_i
      wal_file.compression = splitted[3].downcase.to_sym
    end

    def size_in_bytes(size, identifier)
      raise(ArgumentError, "identifier not one of KiB|MiB|GiB|TiB") if !identifier.match(/(KiB|MiB|GiB|TiB)/)
      size_b = 0
      case identifier
      when "KiB"
        size_b = size * 1024
      when "MiB"
        size_b = size * 1024 ** 2
      when "GiB"
        size_b = size * 1024 ** 3
      when "TiB"
        size_b = size * 1024 ** 4 
      else
        size_b = size
      end
      return size_b.to_i
    end

    def delete(server, backup_id)
      run_barman_command("delete #{server} #{backup_id}")
    end

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
