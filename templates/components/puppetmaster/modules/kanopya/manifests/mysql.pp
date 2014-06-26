class kanopya::mysql::params {
  case $operatingsystem {
    /(?i)(debian|ubuntu)/ : {
      $mysql_package_name        = 'mariadb-galera-server'
      $mysql_client_package_name = 'mariadb-client'
      $mysql_service_provider    = 'init'

      class { 'kanopya::mysql::repos::deb':
        stage => 'system'
      }

      package { 'galera':
        ensure => installed,
      }

      package { 'socat':
        ensure => installed,
      }
    }
    /(?i)(redhat|centos)/ : {
      $mysql_package_name        = 'MariaDB-Galera-server'
      $mysql_client_package_name = 'MariaDB-client'
      $mysql_service_provider    = 'redhat'

      include kanopya::mysql::repos::rh

      Yumrepo['Percona'] -> Package['percona-xtrabackup']
      Yumrepo['MariaDB'] -> Class['::mysql::server']
    }
    default : {
      fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu, RedHat and CentOS are supported")
    }
  }
}

class kanopya::mysql::galera($galera) {
  exec { 'mysql-start':
    command => "service mysql start",
    path    => "/bin:/sbin:/usr/bin:/usr/sbin",
    require => [ Package['mysql-server'],
                 Service['mysqld'],
                 Package['mysql_client'] ]
  }

  database_user { 'wsrep@localhost':
    password_hash => mysql_password('wsrep'),
    require       => Exec['mysql-start'],
  }

  database_grant { "wsrep@localhost":
    privileges => ['all'] ,
    require    => Database_User['wsrep@localhost'],
  }

  $provider = $architecture ? {
    'x86_64' => '/usr/lib64/galera/libgalera_smm.so',
    default  => '/usr/lib/galera/libgalera_smm.so'
  }

  mysql::server::config { 'galera':
    settings => {
      mysqld => {
        wsrep_provider                 => $provider,
        wsrep_cluster_address          => $galera['address'],
        wsrep_cluster_name             => $galera['name'],
        wsrep_sst_method               => 'xtrabackup',
        wsrep_sst_auth                 => "wsrep:wsrep",
        datadir                        => "/var/lib/mysql",
        tmpdir                         => "/tmp",
        binlog_format                  => "ROW",
        default-storage-engine         => "innodb",
        sync_binlog                    => "0",
        innodb_flush_log_at_trx_commit => "0",
        innodb_doublewrite             => "0",
        innodb_autoinc_lock_mode       => "2",
        innodb_locks_unsafe_for_binlog => "1",
        query_cache_size               => "0",
        query_cache_type               => "0",
        wsrep_sst_receive_address      => "$ipaddress",
        max_connect_errors             => "4294967295"
      }
    },
    require  => [ Database_grant['wsrep@localhost'],
                  Package['percona-xtrabackup'] ]
  }
}

class kanopya::mysql::repos::deb {
  $release = downcase($lsbdistcodename)
  $os = downcase($operatingsystem)

  @apt::source { 'Percona':
    location    => 'http://repo.percona.com/apt',
    release     => $release,
    repos       => 'main',
    key         => '1C4CBDCDCD2EFD2A',
    key_server  => 'hkp://keys.gnupg.net',
    include_src => false,
  }

  @apt::source { 'MariaDB':
    location    => "http://ftp.igh.cnrs.fr/pub/mariadb/repo/5.5/${os}",
    release     => $release,
    repos       => 'main',
    key         => 'cbcb082a1bb943db',
    key_server  => 'keyserver.ubuntu.com',
    include_src => false,
  }

  file { '/etc/apt/preferences.d/mariadb-pin-900':
    content => template('kanopya/apt-pinning.erb'),
  }
}

class kanopya::mysql::repos::rh {
  yumrepo { 'Percona':
    baseurl  => 'http://repo.percona.com/centos/$releasever/os/$basearch/',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'http://www.percona.com/downloads/RPM-GPG-KEY-percona'
  }

  yumrepo { 'MariaDB':
    baseurl  => 'http://yum.mariadb.org/5.5/centos6-amd64',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB'
  }
}

class kanopya::mysql(
  $config_hash = {},
  $galera      = {}
) inherits kanopya::mysql::params {

  $config_hash['service_name'] = 'mysql'
  $config_hash['pidfile']      = "${fqdn}.pid"
  $config_hash['bind_address'] = $components[mysql][listen][mysqld][ip]

  file { '/var/run/mysqld':
    ensure  => 'directory',
    owner   => 'mysql',
    group   => 'mysql',
    require => Class['::mysql::server']
  }

  package { 'percona-xtrabackup':
    ensure  => installed,
    require => Package['mysql-server']
  }

  class { '::mysql':
    client_package_name => $kanopya::mysql::params::mysql_client_package_name,
    require             => Package['mysql-server']
  }

  class { '::mysql::server':
    service_name     => 'mysql',
    service_provider => $kanopya::mysql::params::mysql_service_provider,
    config_hash      => $config_hash,
    package_name     => $kanopya::mysql::params::mysql_package_name
  }

  class { 'kanopya::mysql::galera':
    galera => $galera
  }

  Mysql::Db <<| tag == "${fqdn}" |>>
  Database_user <<| tag == "${fqdn}" |>>
  Database_grant <<| tag == "${fqdn}" |>>
}

