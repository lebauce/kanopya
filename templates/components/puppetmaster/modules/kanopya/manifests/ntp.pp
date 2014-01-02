class kanopya::ntp::server(
  $servers = [ "ntp.pool.org", "ntp.lip6.fr", "ntp.ubuntu.com" ]
) {
  class { '::ntp':
    service_ensure => running,
    servers        => $servers,
  }
}

class kanopya::ntp::client(
  $server = "127.0.0.1"
) {
  class { '::ntp':
    service_ensure => stopped,
    servers        => [ $server ],
  }

  package { 'ntpdate':
    name   => 'ntpdate',
    ensure => present
  }

  exec { "ntpdate -b -u ${server}":
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => [ Class['::ntp'],
                 Package['ntpdate'] ]
  }

  cron { 'ntpdate':
    command => "ntpdate -b -u ${server}",
    user    => root,
    hour    => 2,
    require => Package['ntpdate']
  }
}

