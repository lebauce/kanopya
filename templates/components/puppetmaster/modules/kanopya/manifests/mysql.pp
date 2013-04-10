class kanopya::mysql::repo {
    if $operatingsystem =~ /(?i)(centos)/ {
        yumrepo { 'MariaDB':
            baseurl  => 'http://yum.mariadb.org/5.5/centos6-amd64',
            enabled  => '1',
            gpgcheck => '1',
            gpgkey   => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB'
        }
    }
    elsif $operatingsystem =~ /(?i)(debian|ubuntu)/ {
        case $operatingsystem {
            'Debian' : { $release = 'squeeze' }
            'Ubuntu' : { $release = 'precise' }
        }
        apt::source { 'MariaDB':
            location   => 'http://ftp.igh.cnrs.fr/pub/mariadb/repo/5.5/${operatingsystem}',
            release    => $release,
            repos      => 'main',
            key        => '0xcbcb082a1bb943db',
            key_server => 'keyserver.ubuntu.com'
        }
    }
}

class kanopya::mysql($config_hash) {
    class { 'kanopya::mysql::repo':
        before => Class['mysql::server']
    }

    class { 'mysql::server':
        package_name => 'MariaDB-Galera-server',
        service_name => 'mysql',
        config_hash  => $config_hash,
        require      => Class['kanopya::mysql::repo']
    }

    Mysql::Db <<| tag == "${fqdn}" |>>
    Database_user <<| tag == "${fqdn}" |>>
    Database_grant <<| tag == "${fqdn}" |>>
}

