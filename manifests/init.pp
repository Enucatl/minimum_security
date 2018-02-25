class minimum_security (
  $user,
  $password,
  $ssh_key_location,
  $ufw_allow_options={
    "allow_ssh" => {
      port => 22
    }
  },
  $ssh_server_options={
    'PasswordAuthentication' => 'no',
  }
) {
  package { 'fail2ban':
    ensure => present,
  }

  file { "/home/$user/.ssh":
    ensure => "directory",
    group => $user,
    owner => $user,
    mode => "0600",
    before => Wget::Fetch["authorized_keys_download"],
  }

  wget::fetch { $ssh_key_location:
    alias => "authorized_keys_download",
    destination => '/tmp/authorized.keys',
    cache_dir   => '/var/cache/wget',
    notify => File["authorized_keys_file"],
  }

  file { "/home/$user/.ssh/authorized_keys":
    ensure => present,
    mode => "0600",
    group => $user,
    owner => $user,
    alias => "authorized_keys_file",
    source => "/tmp/authorized.keys"
  }

  user { $user:
    ensure => present,
    password => $password,
    shell => '/bin/bash',
    managehome => true,
    before => Class['ssh::server', 'sudo'],
    notify => File["/home/${user}/.ssh"],
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
      "${user}" => {
        ensure => present,
        content => "${user} ALL=(ALL:ALL) ALL",
      },
    },
  }

  include ufw

  create_resources(ufw::allow, $ufw_allow_options)

  class { 'ssh::server':
    options => $ssh_server_options,
  }

  include apt
  include unattended_upgrades
}
