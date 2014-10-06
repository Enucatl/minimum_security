class minimum_security (
  $user="deploy",
  $password,
  $ssh_key_location,
  $ufw_allow_options={
    "allow_ssh" => {
      port => 22
    }
  },
  $ssh_server_options={
      'PasswordAuthentication' => 'no',
      'PermitRootLogin' => 'no',
    }
) {
    package { 'fail2ban':
      ensure => present,
    }

    class key_downloader {
      exec { "/usr/bin/env wget -O authorized.keys --timestamping $ssh_key_location":
        alias => "exec_key_download",
        cwd => "/tmp",
      }

      file { "/home/$user/.ssh":
        ensure => "directory",
        group => "deploy",
        owner => "deploy",
        mode => 700,
        before => File["authorized_keys_file"],
      }

      file { "/home/$user/.ssh/authorized_keys":
        alias => "authorized_keys_file",
        ensure => present,
        source => "/tmp/authorized.keys",
        mode => 600,
        require => Exec["exec_key_download"],
      }
    }

  class { 'key_downloader': }

  user { $user:
    ensure => present,
    password => $password,
    shell => '/bin/bash',
    managehome => true,
    before => Class['ssh::server', 'sudo', 'key_downloader'],
  }

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
        content => 'root ALL=(ALL) NOPASSWD: ALL',
      },
      'deploy' => {
        ensure => present,
        content => 'deploy ALL=(ALL:ALL) ALL',
      },
    },
  }

  include ufw

  create_resources(ufw::allow, $ufw_allow_options)

  class { 'ssh::server':
    options => $ssh_server_options,
  }

  include apt::unattended_upgrades
}
