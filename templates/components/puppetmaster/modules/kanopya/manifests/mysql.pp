class kanopya::mysql::params {
    case $operatingsystem {
        /(?i)(debian|ubuntu)/ : {
            $mysql_package_name = 'mariadb-galera-server'
            class { 'kanopya::mysql::repos::deb': }
        }
        /(?i)(centos)/ : {
            $mysql_package_name = 'MariaDB-Galera-server'
            class { 'kanopya::mysql::repos::rh': }
        }
        default : {
            fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu and CentOS are supported")
        }
    }
}

class kanopya::mysql::galera($galera) {
    $provider = $architecture ? {
        'x86_64' => '/usr/lib64/galera/libgalera_smm.so',
        default  => '/usr/lib/galera/libgalera_smm.so'
    }
    mysql::server::config { 'galera':
        settings => {
            mysqld => {
                wsrep_provider        => $provider,
                wsrep_cluster_address => $galera['address'],
                wsrep_cluster_name    => $galera['name'],
                wsrep_sst_method      => 'xtrabackup',
                wsrep_sst_auth        => ''
            }
        },
        require    => Class['::mysql::server']
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
    file { '/var/run/mysqld':
        ensure  => 'directory',
        owner   => 'mysql',
        group   => 'mysql',
        require => Class['::mysql::server']
    }
    package { 'percona-xtrabackup':
        ensure  => installed
    }
    class { '::mysql::server':
        service_name  => 'mysql',
        config_hash   => $config_hash,
        package_name  => $kanopya::mysql::params::mysql_package_name
    }
    class { 'kanopya::mysql::galera':
        galera  => $galera
    }
    Mysql::Db <<| tag == "${fqdn}" |>>
    Database_user <<| tag == "${fqdn}" |>>
    Database_grant <<| tag == "${fqdn}" |>>
}

