define swap($ensure = present) {
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  }

  if $ensure == present {
    exec { 'swap-on':
      command => 'swapon -a',
      unless  => 'grep partition /proc/swaps',
    }
  } else {
    exec { 'swap-off':
      command => 'swapoff -a',
      onlyif  => 'grep partition /proc/swaps',
    }
  }
}

class kanopya::linux::repositories {
  Apt::Source <| |>
}

class kanopya::linux (
  $files  = [],
  $mounts = [],
  $swaps  = []
) {
  tag("kanopya::operation::poststartnode")

  case $operatingsystem {
    RedHat, CentOS, Fedora: {
      $haltpath = "/etc/rc.d/rc0.d"
      $netscript = "K[0-9][0-9]network"
      $iscsiscript = "K[0-9][0-9]iscsi"
    }

    Ubuntu: {
      $haltpath = "/etc/rc0.d"
      $netscript = "S[0-9][0-9]networking"
      $iscsiscript = "S[0-9][0-9]open-iscsi"
    }

    Debian: {
      $haltpath = "/etc/rc0.d"
      $netscript = "K[0-9][0-9]networking"
      $iscsiscript = "K[0-9][0-9]umountiscsi"
    }

    default: {
      fail("Unrecognized operating system")
    }
  }

  file { '/etc/hosts':
    path   => '/etc/hosts',
    ensure => present,
    mode   => 0644,
    source => "puppet:///kanopyafiles/${sourcepath}/etc/hosts",
    tag    => "kanopya::operation::startnode"
  }

  file { '/etc/resolv.conf':
    path   => '/etc/resolv.conf',
    ensure => present,
    mode   => 0644,
    source => "puppet:///kanopyafiles/${sourcepath}/etc/resolv.conf",
  }

  tidy {'bad-scripts':
    path    => "${haltpath}",
    recurse => true,
    matches => [ $iscsiscript, $netscript ]
  }

  package { 'tzdata':
    name   => 'tzdata',
    ensure => installed
  }

  file { '/etc/localtime':
    require => Package['tzdata'],
    source  => 'file:///usr/share/zoneinfo/CET'
  }

  class { 'kanopya::linux::repositories': }

  if $operatingsystem =~ /(?i)(debian|ubuntu)/ {
    exec { 'apt-get update':
      path    => '/usr/bin',
      tries   => 5,
      require => [ Class['kanopya::linux::repositories'],
                   File['/etc/resolv.conf'] ]
    }
  }

  if $operatingsystem =~ /(?i)(ubuntu)/ {
    package { 'ubuntu-cloud-keyring':
      name    => 'ubuntu-cloud-keyring',
      ensure  => present,
      require => Exec['apt-get update']
    }

    exec { 'apt-get -q update':
      path        => '/usr/bin',
      tries       => 5,
      subscribe   => Package['ubuntu-cloud-keyring'],
      refreshonly => true
    }

    file { '/etc/apt/sources.list.d/ubuntu-cloud-repository.list':
      content => "# ubuntu-cloud-repository\ndeb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main\ndeb-src http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main",
      require => Package['ubuntu-cloud-keyring']
    }
  }

  create_resources('file', $files)
  create_resources('mount', $mounts)
  create_resources('swap', $swaps)
}

