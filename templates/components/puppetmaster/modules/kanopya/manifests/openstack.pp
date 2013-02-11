class kanopya::openstack::repository {
    if $operatingsystem =~ /(?i)(ubuntu)/ {
        package { 'ubuntu-cloud-keyring':
            name => 'ubuntu-cloud-keyring',
            ensure => present,
        }
        apt::source { 'ubuntu-cloud-repository':
            location => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            release  => 'precise-updates/folsom',
            repos    => 'main',
        }
    }
}

class kanopya::keystone($dbserver, $password) {
    @@mysql::db { 'keystone':
        user     => 'keystone',
        password => "${password}",
        host     => "${ipaddress}",
        grant    => ['all'],
        tag      => "${dbserver}",
    }

    Keystone_user <<| tag == "${fqdn}" |>>
}

class kanopya::glance($dbserver, $password, $keystone, $email) {
    @@mysql::db { 'glance':
        user     => 'glance',
        password => "${password}",
        host     => "${ipaddress}",
        grant    => ['all'],
        tag      => "${dbserver}",
    }

    @@keystone_user { 'glance':
        ensure   => present,
        password => "${password}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}"
    }

    class { 'glance::api':
        verbose           => 'False',
        debug             => 'False',
        auth_type         => 'keystone',
        auth_port         => '35357',
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        keystone_password => 'glance',
        sql_connection    => "mysql://glance:glance@${dbserver}/glance",
    }

    class { 'glance::registry':
        verbose           => 'True',
        debug             => 'True',
        auth_type         => 'keystone',
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        keystone_password => 'glance',
        sql_connection    => "mysql://glance:glance@${dbserver}/glance",
    }

    class { 'glance::backend::file': }
}

class kanopya::novacontroller($password, $dbserver, $amqpserver, $keystone, $email) {
    @@rabbitmq_user { 'nova':
        admin    => true,
        password => "${password}",
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}",
    }

    @@mysql::db { 'nova':
            user     => 'nova',
            password => "${password}",
            host     => "${dbserver}",
            grant    => ['all'],
            tag      => "${dbserver}",
    }

    @@keystone_user { 'controller':
        ensure   => present,
        password => "${password}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}"
    }

    class { 'nova::api':
            enabled        => true,
            admin_password => "${password}",
    }
    class { 'nova': sql_connection => "mysql://nova:${password}@${dbserver}/nova", }
    class { 'nova::scheduler': enabled => true, }
    class { 'nova::objectstore': enabled => true, }
    class { 'nova::cert': enabled => true, }
    class { 'nova::vncproxy': enabled => true, }
    class { 'nova::consoleauth': enabled => true, }
}
