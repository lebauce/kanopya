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

class kanopya::mysql::deb($config_hash) {
    $release = $operatingsystem ? {
        /(?i)(debian)/ => 'squeeze',
        /(?i)(ubuntu)/ => 'precise'
    }
    $os = downcase($operatingsystem)
    apt::source { 'MariaDB':
        location   => "http://ftp.igh.cnrs.fr/pub/mariadb/repo/5.5/${os}",
        release    => $release,
        repos      => 'main',
        key        => 'cbcb082a1bb943db',
        key_server => 'keyserver.ubuntu.com',
        before     => Class['::mysql::server']
    }
    class { '::mysql::server':
        service_name => 'mysql',
        config_hash  => $config_hash,
        package_name => 'mariadb-galera-server',
    }
}

class kanopya::mysql::rh($config_hash) {
    yumrepo { 'MariaDB':
        baseurl  => 'http://yum.mariadb.org/5.5/centos6-amd64',
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
        before   => Class['::mysql::server']
    }
    class { '::mysql::server':
        service_name  => 'mysql',
        config_hash   => $config_hash,
        package_name  => 'MariaDB-Galera-server',
    }
}

class kanopya::mysql($config_hash, $galera) {
    file { '/var/run/mysqld':
        ensure => 'directory',
        owner  => 'mysql',
        group  => 'mysql'
    }
    case $operatingsystem {
        /(?i)(debian|ubuntu)/ : {
            class { 'kanopya::mysql::deb':
                config_hash => $config_hash
            }
        }
        /(?i)(centos)/ : {
            class { 'kanopya::mysql::rh':
                config_hash => $config_hash
            }
        }
        default : {
            fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu and CentOS are supported")
        }
    }
    class { 'kanopya::mysql::galera':
        galera  => $galera
    }
    Mysql::Db <<| tag == "${fqdn}" |>>
    Database_user <<| tag == "${fqdn}" |>>
    Database_grant <<| tag == "${fqdn}" |>>
}

