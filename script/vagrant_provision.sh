set -e -x

POSTGRES_VERSION=9.4
BARMAN_VERSION=1.4.1-1.pgdg70+1
VAGRANT_HOSTNAME=packer-debian-7

sudo su -c 'echo "deb     http://apt.postgresql.org/pub/repos/apt wheezy-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo su -c 'echo "deb http://ftp.de.debian.org/debian/ wheezy-backports main" >> /etc/apt/sources.list.d/backports.list'
sudo apt-get update
sudo apt-get install git-core build-essential postgresql-$POSTGRES_VERSION postgresql-server-dev-$POSTGRES_VERSION postgresql-contrib-$POSTGRES_VERSION barman=$BARMAN_VERSION ruby tmux zsh inotify-tools -y --force-yes
sudo gem install bundler

sudo -u postgres createdb -E UTF8 rbarman_development -l en_US.UTF-8 -T template0

cat << EOF | sudo tee /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf
data_directory = '/var/lib/postgresql/$POSTGRES_VERSION/main'
hba_file = '/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf'
ident_file = '/etc/postgresql/$POSTGRES_VERSION/main/pg_ident.conf'
external_pid_file = '/var/run/postgresql/$POSTGRES_VERSION-main.pid'
listen_addresses = '*'
port = 5432
max_connections = 100
unix_socket_directories = '/var/run/postgresql'
ssl = false
shared_buffers = 512MB
dynamic_shared_memory_type = posix
log_line_prefix = '%t [%p-%l] %q%u@%d '
log_timezone = 'UTC'
stats_temp_directory = '/var/run/postgresql/$POSTGRES_VERSION-main.pg_stat_tmp'
datestyle = 'iso, mdy'
synchronous_commit = off
fsync = off
checkpoint_segments = 64
checkpoint_completion_target = 0.9
checkpoint_timeout = 300
timezone = 'UTC'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'

wal_level = 'archive'
archive_mode = on
archive_command = 'rsync -a %p barman@$VAGRANT_HOSTNAME:/var/lib/barman/main/incoming/%f'
archive_timeout = 180
max_standby_archive_delay = 30
EOF

cat << 'EOF' | sudo tee /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf
local all all trust
host all all ::1/128 trust
host all all 0.0.0.0/0 trust
EOF

sudo /etc/init.d/postgresql restart

git clone --recursive https://github.com/sorin-ionescu/prezto.git /home/vagrant/.zprezto


cat << EOF | tee /tmp/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAydnh6l87HMimcIhDkva++qmyYmXj16VSOBiiz6te+25S8xRr
xZVmU3SIXZ3lEAfvO9rP5n9O57/tsCgJsWwY0OvKM64BjyMF15KsTP9JjrJWWRmS
yHeBSaKl2eF/+zzZk+Iqk/uW7+i+KFdRzS1b71SIPwjS8xlTw7kQwqp0MPMEkDRr
l4+8f+3zJjhlSN/IAMUp5fOvWpN8wHofAnl1o0l4GcjDgQeyNPK3oWmDAqsLeY3h
8icnN2s4G/SKLAF28lrs6xtIPssnihgzjzdAgAoyxD76l7zirVMBc4obssbGnMU6
X4/a4kyjBh8YBg3qRfV7NHNvwHzWoc0yx+LRWQIDAQABAoIBAQCX/VxDYpncPqo1
KiXXz7xWetk7hoVdp7qVStetj9jhcl07dDECglCenqzf8Ti+LXtSkpzhbxM3JioP
7tX9puu4xRNofqnl4fVQMb1T7RayQE8MoFkKYhIUJEjGGyqHP3aGCFMPQu6Qj6xA
LCAIYxNKz1gYPsi5DGUqh3u7WSZMhBqUCKRnUHVoUggIqupGCsYDbVQ73w9cUjnz
Fx9C9sRpGZbNLQMmXhEk1UMsmEWAMSMKvG5xbqdlXoWlCq1TEt3ZxHpae7BNrMBk
UL330q5ZcjWghRjNlQBENFG01cppcbq2DfxrfxmPQP5xNxx4djzGBRZWK6Jy97rI
BpDvLsNBAoGBAOdDd7ZsS5eB54ZTGCRA1+NTCtPlSHydKaEmVhIbAxMWDR/Tli1o
3oOHL/cLQV0uEOqje+ZZFXuJkbe+Vxb37u8zVCxTA8MyPyky0S/WqOV/CeNu8Q+q
SRgfY8m/8EPJoFNF0WRTvC0+ZIX0H8tZsfc/O/j/hc4Hk4TM0MvdSu99AoGBAN9x
CLGu4fg//n8c27hnj6SxchWLiQv103y+jXOBRqlvt8+zQ38Qf2IAK2sQUYN5uLf2
oXI9eGG5UJLLYkxupnomucmq4Z2xkh/+KyJ4aaLsvuiqeK2DPc8yQVv3tP00GcAY
4kSuPoSAGUNNW0yCbc8lrMQSrfc409Vu+BS218gNAoGAU/PTDn8rxdlbohCiL+72
MEjiImAWu14WUbDoB/SUXiZgJ1CZMOzj8h1uVSFZ3iit7W/ht5JZURp0sp4/YVAq
Bd29TcXpFMA124/eDp6/e2htv4lzqzsnA8HJaODrqMAWGoS66c/X/RisR1CDBkAO
cfIbpF2mRk/LxqbPmWJBJMUCgYEA1xXJ1rCPmRaQ9u9imjomTdT6Cr9M5xR1xkjv
hNZWnNeLywW23WOWG1IqeV81+Cd9pqhkdMGzVe67HvNk5kpFOqR4hyZVFCVQkjdq
cj4TAeB/TRx8GhqRrxejTtI9iNdUSlQpyw8n4wgkSWL3lcifx51ulzeb+rTbRUMS
z23KfSkCgYEA1Zx9IVRH4p7SXkxdvDWucXnPz+D7RMOpiA6jgnnp2IiI5DbDsISR
eyoAdMB27LxN4bEmglNzA/60rR3FXm3/RAI7X2ZiRWV413sqNJe53oInTavGGNXl
IT/yJCJpDeYfT9JdSQAHpedUS6gvcApZRT4ot7bIQgbwnT+Lwdj68EY=
-----END RSA PRIVATE KEY-----
EOF

cat << EOF | tee /tmp/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJ2eHqXzscyKZwiEOS9r76qbJiZePXpVI4GKLPq177blLzFGvFlWZTdIhdneUQB+872s/mf07nv+2wKAmxbBjQ68ozrgGPIwXXkqxM/0mOslZZGZLId4FJoqXZ4X/7PNmT4iqT+5bv6L4oV1HNLVvvVIg/CNLzGVPDuRDCqnQw8wSQNGuXj7x/7fMmOGVI38gAxSnl869ak3zAeh8CeXWjSXgZyMOBB7I08rehaYMCqwt5jeHyJyc3azgb9IosAXbyWuzrG0g+yyeKGDOPN0CACjLEPvqXvOKtUwFzihuyxsacxTpfj9riTKMGHxgGDepF9Xs0c2/AfNahzTLH4tFZ barman@$VAGRANT_HOSTNAME
EOF

cat << EOF | tee /tmp/ssh-config
Host $VAGRANT_HOSTNAME
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
EOF

sudo mkdir -p /var/lib/postgresql/.ssh
sudo mkdir -p /var/lib/barman/.ssh
sudo cp /tmp/id_rsa* /var/lib/postgresql/.ssh
sudo cp /tmp/id_rsa* /var/lib/barman/.ssh
sudo cp /tmp/ssh-config /var/lib/postgresql/.ssh/config
sudo cp /tmp/ssh-config /var/lib/barman/.ssh/config
sudo cp /tmp/id_rsa.pub /var/lib/postgresql/.ssh/authorized_keys
sudo cp /tmp/id_rsa.pub /var/lib/barman/.ssh/authorized_keys
sudo chown -R postgres:postgres /var/lib/postgresql/.ssh
sudo chown -R barman:barman /var/lib/barman/.ssh
sudo chmod 0700 /var/lib/postgresql/.ssh
sudo chmod 0700 /var/lib/barman/.ssh
sudo chmod -R 0600 /var/lib/postgresql/.ssh/id_rsa
sudo chmod -R 0600 /var/lib/barman/.ssh/id_rsa


cat << EOF | sudo tee /etc/barman.conf
[barman]
; Main directory
barman_home = /var/lib/barman

; System user
barman_user = barman

; Log location
log_file = /var/log/barman/barman.log

; Default compression level: possible values are None (default), bzip2, gzip or custom
;compression = gzip

; Incremental backup support: possible values are None (default), link or copy
;reuse_backup = link

; Pre/post backup hook scripts
;pre_backup_script = env | grep ^BARMAN
;post_backup_script = env | grep ^BARMAN

; Pre/post archive hook scripts
;pre_archive_script = env | grep ^BARMAN
;post_archive_script = env | grep ^BARMAN

; Directory of configuration files. Place your sections in separate files with .conf extension
; For example place the 'main' server section in /etc/barman.d/main.conf
;configuration_files_directory = /etc/barman.d

; Minimum number of required backups (redundancy) - default 0
;minimum_redundancy = 0

; Global retention policy (REDUNDANCY or RECOVERY WINDOW) - default empty
;retention_policy =

; Global bandwidth limit in KBPS - default 0 (meaning no limit)
;bandwidth_limit = 4000

; Immediate checkpoint for backup command - default false
;immediate_checkpoint = false

; Enable network compression for data transfers - default false
;network_compression = false

; Identify the standard behavior for backup operations: possible values are
; exclusive_backup (default), concurrent_backup
;backup_options = exclusive_backup

; Number of retries of data copy during base backup after an error - default 0
;basebackup_retry_times = 0

; Number of seconds of wait after a failed copy, before retrying - default 30
;basebackup_retry_sleep = 30

; Time frame that must contain the latest backup date.
; If the latest backup is older than the time frame, barman check
; command will report an error to the user.
; If empty, the latest backup is always considered valid.
; Syntax for this option is: "i (DAYS | WEEKS | MONTHS)" where i is an
; integer > 0 which identifies the number of days | weeks | months of
; validity of the latest backup for this check. Also known as 'smelly backup'.
;last_backup_maximum_age =

;; ; 'main' PostgreSQL Server configuration
[main]
;; ; Human readable description
description =  "Main PostgreSQL Database"
;;
;; ; SSH options
ssh_command = ssh postgres@$VAGRANT_HOSTNAME
;;
;; ; PostgreSQL connection string
conninfo = host=$VAGRANT_HOSTNAME user=postgres
;;
;; ; Minimum number of required backups (redundancy)
;; ; minimum_redundancy = 1
;;
;; ; Examples of retention policies
;;
;; ; Retention policy (disabled)
;; ; retention_policy =
;; ; Retention policy (based on redundancy)
;; ; retention_policy = REDUNDANCY 2
;; ; Retention policy (based on recovery window)
;; ; retention_policy = RECOVERY WINDOW OF 4 WEEKS
EOF

cd /home/vagrant/.zprezto/runcoms
for rcfile in `ls *`; do ln -s /home/vagrant/.zprezto/runcoms/$rcfile /home/vagrant/.$rcfile; done
echo "vagrant" | chsh -s /usr/bin/zsh
echo 'export PGUSER="postgres"' >> ~/.zshrc
echo 'export PGDATABASE="rbarman_development"' >> ~/.zshrc

cat << EOF | tee /home/vagrant/.zpreztorc
zstyle ':prezto:*:*' color 'yes'
zstyle ':prezto:load' pmodule \
  'environment' \
  'terminal' \
  'editor' \
  'history' \
  'directory' \
  'spectrum' \
  'utility' \
  'completion' \
  'prompt' \
  'history-substring-search'

zstyle ':prezto:module:editor' key-bindings 'vi'
zstyle ':prezto:module:prompt' theme 'sorin'
EOF


cat << EOF | tee /home/vagrant/.tmux.conf
set-window-option -g mode-keys vi
bind-key -t vi-copy 'v' begin-selection
bind-key -t vi-copy 'y' copy-selection
bind p paste-buffer
set -g status-bg colour232
set -g status-fg white
EOF
