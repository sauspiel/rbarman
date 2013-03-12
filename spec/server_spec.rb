require 'rspec'

include RBarman

describe Server do

  before :each do
    @server = Server.new('test')
  end

  describe "#new" do
    it 'should be an instance of a Server object' do
      @server.should be_an_instance_of Server
    end

    it 'should initialize name' do
      expect(@server.name).to eq('test')
    end
  end

  describe "#name" do
    it 'should assign a name' do
      @server.name = "test2"
      expect(@server.name).to eq("test2")
    end
  end

  describe "#active" do
    it 'should assign active' do
      @server.active = false
      expect(@server.active).to eq(false)

      @server.active = true
      expect(@server.active).to eq(true)
    end
  end

  describe "#ssh_cmd" do
    it 'should assign a ssh command string' do
      @server.ssh_cmd = "ssh abc@xyz.com"
      expect(@server.ssh_cmd).to eq("ssh abc@xyz.com")
    end
  end

  describe "#conn_info" do
    it 'should assign a connection info string' do
      @server.conn_info = "host=127.0.0.1"
      expect(@server.conn_info).to eq("host=127.0.0.1")
    end
  end

  describe "#backup_dir" do
    it 'should assign a backup directory path' do
      @server.backup_dir = "/var/lib/barman/test"
      expect(@server.backup_dir).to eq("/var/lib/barman/test")
    end
  end

  describe "#base_backups_dir" do
    it 'should assign a base backups directory path' do
      @server.base_backups_dir = "/var/lib/barman/test/base"
      expect(@server.base_backups_dir).to eq("/var/lib/barman/test/base")
    end
  end

  describe "#wals_dir" do
    it 'should assign a path to wals directory' do
      @server.wals_dir = "/var/lib/barman/test/wals"
      expect(@server.wals_dir).to eq("/var/lib/barman/test/wals")
    end
  end

  describe "#ssh_check_ok" do
    it 'should assign a boolean' do
      @server.ssh_check_ok = true
      expect(@server.ssh_check_ok).to eq(true)
    end
  end

  describe "#pg_conn_ok" do
    it 'should assign a boolean' do
      @server.pg_conn_ok = true
      expect(@server.pg_conn_ok).to eq(true)
    end
  end
end
