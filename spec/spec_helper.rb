require 'rspec'
require 'rbarman'
require 'rbarman/string'
require 'rbarman/configuration'
require 'rbarman/wal_file'
require 'rbarman/wal_files'
require 'rbarman/backup'
require 'rbarman/cli_command'
require 'rbarman/server'

RSpec.configure do |config|
  config.color_enabled  = true
  config.formatter      = 'documentation' 
end
