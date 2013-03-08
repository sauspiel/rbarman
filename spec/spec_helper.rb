require 'rspec'
require 'rbarman'
require 'rbarman/configuration'
require 'rbarman/wal_file.rb'
require 'rbarman/backup.rb'
require 'rbarman/cli_command.rb'

RSpec.configure do |config|
  config.color_enabled  = true
  config.formatter      = 'documentation' 
end
