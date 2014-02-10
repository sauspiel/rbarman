require 'spec_helper'

include RBarman

describe CliCommand do

  before :each do
    File.stub!(:exists?).and_return(true)
    @cmd = CliCommand.new("/path/to/barman", "/path/to/barman_home")
  end

  describe "#new" do
    it 'should be an instance of a CliCommand object' do
      expect(@cmd).to be_an_instance_of CliCommand
    end

    it 'should set binary' do
      expect(@cmd.binary).to eq('/path/to/barman')
    end

    it 'should set barman_home' do
      expect(@cmd.barman_home).to eq('/path/to/barman_home')
    end
    
    it 'instance variables should set by configuration' do
      c = CliCommand.new
      expect(c.binary).to eq('/usr/bin/barman')
      expect(c.barman_home).to eq(ENV['HOME'])
    end
  end

  describe "binary=" do
    it 'should raise ArgumentError if binary does not exist' do
      File.stub!(:exists?).and_return(false)
      lambda { @cmd.binary = "/bin/true" }.should raise_error(ArgumentError)
    end

    it 'should rais ArgumentError if arg does not end with \'barman\'' do
      File.stub!(:exists?).and_return(true)
      File.stub!(:basename).and_return('abc')
      lambda { @cmd.binary = "/bin/true" }.should raise_error(ArgumentError)
    end

    it 'should set binary to value of path if exists' do
      File.stub!(:exists?).and_return(true)
      File.stub!(:basename).and_return('barman')
      @cmd.binary = "/path/to/barman"
      @cmd.binary.should == "/path/to/barman"
    end
  end

  describe "barman_home=" do
    it 'should raise ArgumentError if path does not exist' do
      File.stub!(:exists?).and_return(false)
      lambda { @cmd.barman_home = "/bin/true" }.should raise_error(ArgumentError)
    end

    it 'should set barman_home to value of path if exists' do
      File.stub!(:exists?).and_return(true)
      @cmd.barman_home = "/path/to/barman_home"
      @cmd.barman_home == "/path/to/barman_home"
    end
  end

  describe "parse_backup_list" do

    it 'should return an array of backup' do
      lines = [
        "test 20130225T192654 - Tue Feb 26 05:50:05 2013 - Size: 217.0 GiB - WAL Size: 72.0 GiB",
        "test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB"
      ]
      backups = @cmd.parse_backup_list(lines)
      backups[0].id.should == "20130225T192654"
      backups[0].server.should == "test"
      backups[0].size.should == CliCommand.size_in_bytes(217.0, "GiB")
      backups[0].wal_file_size.should == CliCommand.size_in_bytes(72.0, "GiB")

      backups[1].id.should == "20130218T080002"
      backups[1].server.should == "test"
      backups[1].size.should == CliCommand.size_in_bytes(213.0, "GiB")
      backups[1].wal_file_size.should == CliCommand.size_in_bytes(130.0, "GiB")
    end

    it 'should detect a started or failed backup' do
      lines = [
              "test 20130225T192654 - Tue Feb 26 05:50:05 2013 - FAILED",
              "test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB",
              "test 20130218T080013 - Mon Feb 13 18:32:22 2013 - STARTED"
      ]

      backups = @cmd.parse_backup_list(lines)
      backups[0].id.should == "20130225T192654"
      backups[0].server.should == "test"
      backups[0].size.should == nil
      backups[0].wal_file_size.should == nil
      backups[0].status.should == :failed

      backups[1].id.should == "20130218T080002"
      backups[1].server.should == "test"
      backups[1].size.should == CliCommand.size_in_bytes(213.0, "GiB")
      backups[1].wal_file_size.should == CliCommand.size_in_bytes(130.0, "GiB")
      backups[1].status.should == :done

      backups[2].id.should == "20130218T080013"
      backups[2].server.should == "test"
      backups[2].size.should == nil
      backups[2].wal_file_size.should == nil
      backups[2].status.should == :started



    end
  end

  describe ".size_in_bytes" do
    it 'should raise ArgumentError if identifier is not like B|KiB|MiB|GiB|TiB ' do
      lambda { CliCommand.size_in_bytes(1,"a") }.should raise_error(ArgumentError)
    end

    it 'should return bytes from B' do
      CliCommand.size_in_bytes(2048, 'B').should == 2048
    end

    it 'should return bytes from KiB' do
      CliCommand.size_in_bytes(2048, 'KiB').should == 2048 * 1024
    end

    it 'should return bytes from MiB' do
      CliCommand.size_in_bytes(2048, 'MiB').should == 2048 * 1024 ** 2
    end

    it 'should return bytes from GiB' do
      CliCommand.size_in_bytes(2048, 'GiB').should == 2048 * 1024 ** 3    
    end

    it 'should return bytes from TiB' do
      CliCommand.size_in_bytes(2048, 'TiB').should == 2048 * 1024 ** 4
    end

    it 'should return an integer' do
      CliCommand.size_in_bytes(2048.0, 'KiB').should be_a_kind_of(Integer)
    end
  end

  describe "backups" do
    it 'should return an empty array if there are no backups' do
      @cmd.stub!(:run_barman_command).and_return([])
      @cmd.backups("test").should be_an_instance_of Backups
    end

    it 'should return an array of backup if there are backups' do
      backup_list = [
        "test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB",
      ]
      backup_info_lines = [
        "begin_time=2013-02-25 19:26:54.852814",
        "end_time=2013-02-26 05:50:05.523594",
        "status=DONE",
        "size=233655051378",
        "pgdata=/var/lib/postgresql/9.2/main",
        "timeline=1",
        "begin_wal=0000000100000552000000B6",
        "end_wal=000000010000055700000031",
        "version=90204"
      ]
      wal_files = [
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BC",
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BD"
      ]

      
      xlog_db = Hash.new
      xlog_db["00000001000005A9000000BC"] = {:size => 4684503, :created => 1360568429.0, :compression => :bzip2 }
      xlog_db["00000001000005A9000000BD"] = {:size => 5099998, :created => 1360568442.0, :compression => :bzip2 }


      @cmd.stub(:run_barman_command).and_return(backup_list, wal_files)
      @cmd.stub(:file_content).and_return(backup_info_lines)
      @cmd.stub(:read_xlog_db).and_return(xlog_db)
      backups = @cmd.backups("test", { :with_wal_files => true })
      expect(backups).to be_an_instance_of Backups
      expect(backups.count).to eq(1)
      expect(backups[0].id).to eq("20130218T080002")
      expect(backups[0].size).to eq(233655051378)
      expect(backups[0].status).to eq(:done)
      expect(backups[0].wal_file_size).to eq(9784501)
      expect(backups[0].wal_files.count).to eq(2)
    end
  end

  describe "backup" do
    it 'should raise ArgumentError if arg is nil' do
      expect { @cmd.backup("test", nil) }.to raise_error(ArgumentError)
    end

    it 'should return nil if there is no such backup' do
      backup_list = [
        "test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB",
        "test 20130222T080002 - Mon Feb 22 18:11:16 2013 - Size: 248.0 GiB - WAL Size: 135.0 GiB",
      ]
      @cmd.stub!(:run_barman_command).and_return(backup_list, nil)
      backup = @cmd.backup("test", "20130222T081210")
      expect(backup).to eq(nil)
    end

    it 'should return a specific backup without wal files' do
      backup_list = [
        "test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB",
        "test 20130222T080002 - Mon Feb 22 18:11:16 2013 - Size: 248.0 GiB - WAL Size: 135.0 GiB",
      ]
      wal_files = [
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BC",
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BD"
      ]

      xlog_db = Hash.new
      xlog_db["00000001000005A9000000BC"] = {:size => 4684503, :created => 1360568429.0, :compression => :bzip2 }
      xlog_db["00000001000005A9000000BD"] = {:size => 5099998, :created => 1360568442.0, :compression => :bzip2 }


      backup_info_lines = [
        "begin_time=2013-02-25 19:26:54.852814",
        "end_time=2013-02-26 05:50:05.523594",
        "status=DONE",
        "size=233655051378",
        "pgdata=/var/lib/postgresql/9.2/main",
        "timeline=1",
        "begin_wal=0000000100000552000000B6",
        "end_wal=000000010000055700000031"
      ]
      @cmd.stub(:run_barman_command).and_return(backup_list, wal_files)
      @cmd.stub(:file_content).and_return(backup_info_lines)
      @cmd.stub(:read_xlog_db).and_return(xlog_db)
      backup = @cmd.backup("test", "20130222T080002", { :with_wal_files => false })
      expect(backup.id).to eq("20130222T080002")
      expect(backup.wal_files).to eq(nil)
    end
  end


  describe "parse_backup_info_file" do
    it 'should raise ArgumentError if arg is not of type Backup' do
      expect { @cmd.parse_backup_info_file(1) }.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError if backup.id is not set' do
      expect { @cmd.parse_backup_info_file(Backup.new) }.to raise_error(ArgumentError)
    end

    it 'should raise ArgumentError if backup.server is not set' do
      expect { @cmd.parse_backup_info_file(Backup.new) }.to raise_error(ArgumentError)
    end

    it 'should set backup attributes to according values in backup_info' do
      lines = [
        "begin_time=2013-02-25 19:26:54.852814",
        "end_time=2013-02-26 05:50:05.523594",
        "status=DONE",
        "size=233655051378",
        "pgdata=/var/lib/postgresql/9.2/main",
        "timeline=1",
        "begin_wal=0000000100000552000000B6",
        "end_wal=000000010000055700000031",
        "version=90204",
      ]
      @cmd.stub!(:file_content).and_return(lines)

      backup = Backup.new.tap { |b| b.id = "20130304T080002"; b.server = "test" }
      @cmd.parse_backup_info_file(backup)
      expect(backup.backup_start).to eq(Time.parse(lines[0].split("=")[1]))
      expect(backup.backup_end).to eq(Time.parse(lines[1].split("=")[1]))
      expect(backup.status).to eq(lines[2].split("=")[1].downcase.to_sym)
      expect(backup.size).to eq(lines[3].split("=")[1].to_i)
      expect(backup.timeline).to eq(1)
      expect(backup.begin_wal).to eq(WalFile.parse("0000000100000552000000B6"))
      expect(backup.end_wal).to eq(WalFile.parse("000000010000055700000031"))
      expect(backup.pg_version).to eq(90204)
    end

    it 'should not set size or end_* if backup has started' do
      lines = [
        "begin_time=2013-02-25 19:26:54.852814",
        "end_time=None",
        "status=STARTED",
        "size=None",
        "pgdata=/var/lib/postgresql/9.2/main",
        "timeline=1",
        "begin_wal=0000000100000552000000B6",
        "end_wal=None",
        "version=90204",
      ]
      @cmd.stub!(:file_content).and_return(lines)

      backup = Backup.new.tap { |b| b.id = "20130304T080002"; b.server = "test" }
      @cmd.parse_backup_info_file(backup)
      expect(backup.backup_start).to eq(Time.parse(lines[0].split("=")[1]))
      expect(backup.backup_end).to eq(nil)
      expect(backup.status).to eq(lines[2].split("=")[1].downcase.to_sym)
      expect(backup.size).to eq(nil)
      expect(backup.timeline).to eq(1)
      expect(backup.begin_wal).to eq(WalFile.parse("0000000100000552000000B6"))
      expect(backup.end_wal).to eq(nil)
      expect(backup.pg_version).to eq(90204)
    end
  end

  describe "parse_wal_files_list" do
    it 'should return an array of WalFiles' do
      lines = [
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BC",
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BD"
      ]
      wal_files = @cmd.parse_wal_files_list(lines)
      expect(wal_files.count).to eq(2)
      expect(wal_files[0]).to eq(WalFile.parse("00000001000005A9000000BC"))
      expect(wal_files[1]).to eq(WalFile.parse("00000001000005A9000000BD"))
    end
  end

  describe "wal_files" do
    it 'should return an array of WalFiles' do
      lines = [
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BC",
        "/var/lib/barman/test/wals/00000001000005A9/00000001000005A9000000BD"
      ]

      xlog_db = Hash.new
      xlog_db["00000001000005A9000000BC"] = {:size => 4684503, :created => 1360568429.0, :compression => :bzip2 }
      xlog_db["00000001000005A9000000BD"] = {:size => 5099998, :created => 1360568442.0, :compression => :bzip2 }
      xlog_db["00000001000005A9000000BD.00000020.backup"] = {:size => 249, :created => 1360562212.0, :compression => :none }

      @cmd.stub!(:run_barman_command).and_return(lines)
      @cmd.stub!(:read_xlog_db).and_return(xlog_db)

      wal_files = @cmd.wal_files("test", "123")
      expect(wal_files.count).to eq(2)
    end
  end

  describe "parse_show_server_lines" do
    it 'should create a valid Server object' do
      lines = [
        "Server test:", 
        "\tactive: true", 
        "\tdescription: PostgreSQL Master Server @ db.testdomain.com", 
        "\tssh_command: ssh postgres@27.118.19.4", 
        "\tconninfo: host=127.0.0.1 user=postgres port=25432", 
        "\tbackup_directory: /var/lib/barman/test", 
        "\tbasebackups_directory: /var/lib/barman/test/base", 
        "\twals_directory: /var/lib/barman/test/wals", 
        "\tincoming_wals_directory: /var/lib/barman/test/incoming", 
        "\tlock_file: /var/lib/barman/test/test.lock", 
        "\tcompression: bzip2", "\tcustom_compression_filter: None", 
        "\tcustom_decompression_filter: None", 
        "\tretention_policy_mode: auto", 
        "\tretention_policy: None", 
        "\twal_retention_policy: main", 
        "\tpre_backup_script: None", 
        "\tpost_backup_script: None", 
        "\tminimum_redundancy: 0", 
        "\tcurrent_xlog: 00000001000005D800000096", 
        "\tlast_shipped_wal: 00000001000005D800000095", 
        "\tarchive_command: /var/lib/postgresql/9.2/main/archive_command.sh %p %f", 
        "\tserver_txt_version: 9.2.3", 
        "\tdata_directory: /var/lib/postgresql/9.2/main", 
        "\tarchive_mode: on", 
        "\tconfig_file: /etc/postgresql/9.2/main/postgresql.conf", 
        "\thba_file: /etc/postgresql/9.2/main/pg_hba.conf", 
        "\tident_file: /etc/postgresql/9.2/main/pg_ident.conf"
      ]

      s = @cmd.parse_show_server_lines("test", lines)
      expect(s.name).to eq("test")
      expect(s.active).to eq(true)
      expect(s.ssh_cmd).to eq("ssh postgres@27.118.19.4")
      expect(s.conn_info).to eq("host=127.0.0.1 user=postgres port=25432")
      expect(s.backup_dir).to eq("/var/lib/barman/test")
      expect(s.base_backups_dir).to eq("/var/lib/barman/test/base")
      expect(s.wals_dir).to eq("/var/lib/barman/test/wals")
      expect(s.pg_version).to eq("9.2.3")
    end
  end

  describe "parse_check_lines" do
    it 'should raise ArgumentError if server is nil' do
      expect {@cmd.parse_check_lines(nil, [])}.to raise_error(ArgumentError)
    end

    it 'should assign parsed values to a server object' do
      s = Server.new('test')

      lines = [
        "Server test:", 
        "\tssh: OK", 
        "\tPostgreSQL: OK", 
        "\tarchive_mode: OK", 
        "\tarchive_command: OK", 
        "\tdirectories: OK", 
        "\tretention policy settings: OK", 
        "\tcompression settings: OK", 
        "\tminimum redundancy requirements: OK (have 4 backups, expected at least 0)"
      ]

      @cmd.parse_check_lines(s, lines)
      expect(s.ssh_check_ok).to eq(true)
      expect(s.pg_conn_ok).to eq(true)
    end
  end

  describe "server" do
    it 'should create a valid server object' do

      backup_list = [
        "test 20130218T080002 - Mon Feb 18 18:11:16 2013 - Size: 213.0 GiB - WAL Size: 130.0 GiB",
      ]

      backup_info_lines = [
        "begin_time=2013-02-25 19:26:54.852814",
        "end_time=2013-02-26 05:50:05.523594",
        "status=DONE",
        "size=233655051378",
        "pgdata=/var/lib/postgresql/9.2/main",
        "timeline=1",
        "begin_wal=0000000100000552000000B6",
        "end_wal=000000010000055700000031"
      ]

      show_lines = ["\tactive: true"]
      check_lines = ["\tssh: OK"]
      @cmd.stub!(:run_barman_command).and_return(show_lines, check_lines, backup_list)
      @cmd.stub!(:file_content).and_return(backup_info_lines)
      server = @cmd.server("test123", { :with_backups => true })
      expect(server.name).to eq("test123")
      expect(server.active).to eq(true)
      expect(server.ssh_check_ok).to eq(true)
      expect(server.backups.count).to eq(1)
      expect(server.backups[0].size).to eq(233655051378)
    end
  end

  describe "parse_list_server_lines" do
    it 'should return server names' do
      lines = [
        "testdb1 - description for testdb1", 
        "testdb2 - description for testdb2"
      ]
      names = @cmd.parse_list_server_lines(lines)
      expect(names.count).to eq(2)
      expect(names[0]).to eq("testdb1")
      expect(names[1]).to eq("testdb2")
    end
  end

  describe "create_recovery_cmd_args" do
    it 'should return an arguments string' do
      t = Time.now
      h = Hash.new
      h[:remote_ssh_cmd] = '123'
      h[:exclusive] = true
      h[:target_time] = t
      h[:target_xid] = 1

      args = @cmd.create_recovery_cmd_args(h)
      expect(args).to eq("--remote-ssh-command='123' --target-time '#{t.to_s}' --target-xid 1 --exclusive")

      h = Hash.new
      args = @cmd.create_recovery_cmd_args(h)
      expect(args).to eq("")
    end
  end

end
