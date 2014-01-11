# Class: mesos::slave
#
# This module manages Mesos slave
#
# Parameters:
#  [*enable*] - install Mesos slave service
#              (default: true)
#  [*master*] - ip address of Mesos master
#              (default: localhost)
#  [*master_port*] - Mesos master's port
#              (default 5050)
#  [*zookeeper*] - Zookeeper URL string (which keeps track
#                of current Mesos master)
#  [*work_dir*] - directory for storing task's temporary files
#              (default: /tmp/mesos)
#  [*isolation*] - isolation mechanism - either 'process' or 'cgroups'
#
#  [*options*] any extra arguments that are not named here could be
#              stored in a hash:
#
#                options => { "key" => "value" }
#
#              which is serialized to disk and then passed to mesos-slave as:
#
#                --key=value
#
# Sample Usage:
#
# class{ 'mesos::slave':
#   master      => '10.0.0.1',
#   master_port => 5050,
# }
#

class mesos::slave (
  $enable      = true,
  $port        = 5051,
  $work_dir    = '/tmp/mesos',
  $checkpoint  = false,
  $isolation   = 'process',
  $conf_dir    = '/etc/mesos-slave',
  $conf_file   = '/etc/default/mesos-slave',
  $master      = $mesos::master,
  $master_port = $mesos::master_port,
  $zookeeper   = $mesos::zookeeper,
  $owner       = $mesos::owner,
  $group       = $mesos::group,
  $env_var     = {},
  $cgroups     = {},
  $options     = {},
) inherits mesos {

  validate_hash($env_var)
  validate_hash($cgroups)

  file { $conf_dir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  # file containing only zookeeper URL
  file { '/etc/mesos/zk':
    ensure  => defined($zookeeper) ? {
      true  => present,
      false => absent,
    },
    content => $zookeeper,
    owner   => $owner,
    group   => $group,
  }

  # stores properties in file structure
  create_resources(mesos::property,
    mesos_hash_parser($cgroups, 'cgroups'),
    { dir => '/etc/mesos-slave' }
  )

  create_resources(mesos::property,
    mesos_hash_parser($options),
    { dir => '/etc/mesos-slave' }
  )

  file { $conf_file:
    ensure  => 'present',
    content => template('mesos/slave.erb'),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    require => [File['/etc/mesos/zk'], File[$conf_dir], Package['mesos']],
  }

  # Install mesos-slave service
  mesos::service { 'slave':
    enable     => $enable,
    require    => File[$conf_file],
  }
}
