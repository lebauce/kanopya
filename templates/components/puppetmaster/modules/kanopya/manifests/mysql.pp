class kanopya::mysql::params {
    case $operatingsystem {
        /(?i)(debian|ubuntu)/ : {
            $mysql_package_name        = 'mariadb-galera-server'
            $mysql_client_package_name = 'mariadb-client'
            class { 'kanopya::mysql::repos::deb': }
        }
        /(?i)(centos)/ : {
            $mysql_package_name        = 'MariaDB-Galera-server'
            $mysql_client_package_name = 'MariaDB-client'
            class { 'kanopya::mysql::repos::rh': }
        }
        default : {
            fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu and CentOS are supported")
        }
    }
}

class kanopya::mysql::galera($galera) {
    exec { 'mysql-start':
        command => "service mysql start",
        path    => "/bin:/sbin:/usr/bin:/usr/sbin",
        require => Package['mysql-server']
    }
    database_user { 'wsrep@localhost':
        password_hash => mysql_password('wsrep'),
        require       => Exec['mysql-start'],
    }
    database_grant { "wsrep@localhost":
        privileges => ['all'] ,
        require    => Database_User['wsrep@localhost'],
    }
    exec { 'mysql-stop':
        command => "service mysql stop",
        path    => "/bin:/sbin:/usr/bin:/usr/sbin",
        require => Database_grant["wsrep@localhost"]
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
                wsrep_sst_receive_address      => "$ipaddress"
            }
        },
        require    => [ Exec['mysql-stop'], Package['percona-xtrabackup'] ]
    }
}

class kanopya::mysql::repos::deb {
    $release = $operatingsystem ? {
        /(?i)(debian)/ => 'squeeze',
        /(?i)(ubuntu)/ => 'precise'
    }
    $os = downcase($operatingsystem)
    apt::source { 'Percona':
        location   => 'http://repo.percona.com/apt',
        release    => $release,
        repos      => 'main',
        key        => '1C4CBDCDCD2EFD2A',
        key_server => 'hkp://keys.gnupg.net',
        before     => Package['percona-xtrabackup']
    }
    apt::source { 'MariaDB':
        location   => "http://ftp.igh.cnrs.fr/pub/mariadb/repo/5.5/${os}",
        release    => $release,
        repos      => 'main',
        key        => 'cbcb082a1bb943db',
        key_server => 'keyserver.ubuntu.com',
        before     => Class['::mysql::server']
    }
}

class kanopya::mysql::repos::rh {
    yumrepo { 'Percona':
        baseurl  => 'http://repo.percona.com/centos/$releasever/os/$basearch/',
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => 'http://www.percona.com/downloads/RPM-GPG-KEY-percona',
        before   => Package['percona-xtrabackup']
    }
    yumrepo { 'MariaDB':
        baseurl  => 'http://yum.mariadb.org/5.5/centos6-amd64',
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
        before   => Class['::mysql::server']
    }
}

class kanopya::mysql($config_hash, $galera) inherits kanopya::mysql::params {
    $config_hash['service_name'] = 'mysql'
    $config_hash['pidfile']      = "${fqdn}.pid"
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
    class { '::mysql::server':
        service_name   => 'mysql',
        config_hash    => $config_hash,
        package_name   => $kanopya::mysql::params::mysql_package_name
    }
    Mysql::Db <<| tag == "${fqdn}" |>>
    Database_user <<| tag == "${fqdn}" |>>
    Database_grant <<| tag == "${fqdn}" |>>
    class { 'kanopya::mysql::galera':
        galera       => $galera
    }
    class { '::mysql':
        package_name => $kanopya::mysql::params::mysql_client_package_name,
        require      => Package['mysql-server']
    }
}

