package { 'fail2ban':
  ensure => present,
}

user { 'deploy':
  ensure => present,
  password => '$1$D5KK5H7a$OCs4OnweVdEe/ll2ZevPd1',
  shell => '/bin/bash',
  managehome => true,
  before => Class['ssh::server', 'sudo', 'key_downloader'],
}

class key_downloader {
  exec { "/usr/bin/env wget --timestamping https://github.com/enucatl.keys":
    alias => "exec_key_download",
    cwd => "/tmp"
  }

  file { "/home/deploy/.ssh/authorized_keys":
    ensure => present,
    source => "/tmp/enucatl.keys",
    require => Exec["exec_key_download"]
  }
}

class { 'key_downloader': }

class { 'sudo':
  keep_os_defaults => false,
  defaults_hash => {
    env_reset => true,
    mail_badpass => true,
    secure_path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  },
  confs_hash => {
    'root' => {
      ensure => present,
      content => 'root ALL=(ALL) NOPASSWD: ALL'
    },
    'deploy' => {
      ensure => present,
      content => 'deploy ALL=(ALL:ALL) ALL'
    },
  },
}

include ufw

ufw::allow { "allow-ssh-from-all":
  port => 22,
}

ufw::allow { "allow-http":
  port => 80
}

ufw::allow { "allow-https":
  port => 443
}

class { 'ssh::server':
  options => {
    'PasswordAuthentication' => 'no',
    'PermitRootLogin' => 'no',
    'AllowUsers' => 'deploy@*.dynamic.hispeed.ch deploy@pc9689.psi.ch',
  },
}

include apt::unattended_upgrades
