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

    class { 'keystone::endpoint':
        public_address   => "${fqdn}",
        admin_address    => "${fqdn}",
        internal_address => "${fqdn}",
    }

    Keystone_user <<| tag == "${fqdn}" |>>
    Keystone_user_role <<| tag == "${fqdn}" |>>
    Keystone_service <<| tag == "${fqdn}" |>>
    Keystone_endpoint <<| tag == "${fqdn}" |>>

    Class['kanopya::openstack::repository'] -> Class['kanopya::keystone']
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

    @@keystone_user_role { "glance@services":
        ensure  => present,
        roles   => 'admin',
        tag     => "${keystone}"
    }

    @@keystone_service { 'glance':
        ensure      => present,
        type        => 'image',
        description => "Openstack Image Service",
        tag         => "${keystone}"
    }

    @@keystone_endpoint { "RegionOne/glance":
        ensure       => present,
        public_url   => "http://${fqdn}:9292/v2",
        admin_url    => "http://${fqdn}:9292/v2",
        internal_url => "http://${fqdn}:9292/v2",
        tag          => "${keystone}"
    }

    class { 'glance::api':
        verbose           => 'True',
        debug             => 'True',
        auth_type         => '',
        auth_port         => '35357',
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        keystone_password => 'glance',
        sql_connection    => "mysql://glance:${password}@${dbserver}/glance",
    }

    class { 'glance::registry':
        verbose           => 'True',
        debug             => 'True',
        auth_type         => '',
        keystone_tenant   => 'services',
        keystone_user     => 'glance',
        keystone_password => 'glance',
        sql_connection    => "mysql://glance:${password}@${dbserver}/glance",
    }

    class { 'glance::backend::file': }

    Class['kanopya::openstack::repository'] -> Class['kanopya::glance']
}

class kanopya::novacontroller($password, $dbserver, $amqpserver, $keystone, $email, $glance) {
    @@rabbitmq_user { 'nova':
        admin    => true,
        password => "${password}",
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}",
    }

    @@rabbitmq_user_permissions { "nova@/":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        tag                  => "${amqpserver}",
    }

    @@keystone_user { 'nova':
        ensure   => present,
        password => "${password}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}",
    }

    @@keystone_user_role { 'nova@services':
        ensure  => present,
        roles   => 'admin',
        tag     => "${keystone}",
    }

    @@keystone_service { 'nova':
        ensure      => present,
        type        => 'controller',
        description => 'Openstack nova controller',
        tag         => "${keystone}",
    }

    @@keystone_endpoint { 'RegionOne/nova':
        ensure       => present,
        public_url   => "http://${fqdn}:8774/v2.0",
        admin_url    => "http://${fqdn}:8774/v2.0",
        internal_url => "http://${fqdn}:8774/v2.0",
        region       => "RegionOne",
        tag          => "${keystone}",
    }

    @@mysql::db { 'nova':
            user     => 'nova',
            password => "${password}",
            host     => "${ipaddress}",
            grant    => ['all'],
            tag      => "${dbserver}",
    }

    class { 'memcached':
        listen_ip => '127.0.0.1',
    }

    class { 'horizon': }

    class { 'nova::api':
            enabled        => true,
            admin_password => "${password}",
            auth_host      => "${keystone}",
    }

    class { 'nova':
        sql_connection      => "mysql://nova:${password}@${dbserver}/nova",
        rabbit_host         => "${amqpserver}",
        glance_api_servers  => "${glance}",
    }

    class { 'nova::scheduler': enabled => true, }
    class { 'nova::objectstore': enabled => true, }
    class { 'nova::cert': enabled => true, }
    class { 'nova::vncproxy': enabled => true, }
    class { 'nova::consoleauth': enabled => true, }

    Class['kanopya::openstack::repository'] -> Class['kanopya::novacontroller']
}

class kanopya::novacompute($amqpserver, $dbserver, $glance, $keystone, $password) {
    class { 'nova':
        # set sql and rabbit to false so that the resources will be collected
        sql_connection     => "mysql://nova:${password}@${dbserver}/nova",
        rabbit_host        => "${amqpserver}",
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "${glance}",
        rabbit_userid      => "nova",
        rabbit_password    => "nova"
    }

    class { 'nova::api':
        enabled        => true,
        admin_password => "nova",
        auth_host      => "${keystone}",
    }

    class { 'nova::compute':
        enabled => true,
    }

    class { 'nova::compute::libvirt':
        libvirt_type => 'qemu',
    }

    @@keystone_service { 'compute':
        ensure      => present,
        type        => "compute",
        description => "Nova Compute Service",
        tag         => "${keystone}"
    }

    @@keystone_endpoint { "RegionOne/compute":
        ensure       => present,
        public_url   => "http://${fqdn}:8774/v2/\$(tenant_id)s",
        admin_url    => "http://${fqdn}:8774/v2/\$(tenant_id)s",
        internal_url => "http://${fqdn}:8774/v2/\$(tenant_id)s",
        tag          => "${keystone}"
    }

    @@database_user { "nova@${ipaddress}":
        password_hash => mysql_password("${password}"),
        tag           => "${dbserver}",
    }

    @@database_grant { "nova@${ipaddress}/nova":
        privileges => ['all'] ,
        tag        => "${dbserver}"
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::novacompute']
}

class kanopya::quantum_($amqpserver, $dbserver, $keystone, $password) {
    class { 'quantum':
        rabbit_password => "${password}",
        rabbit_host     => "${amqpserver}",
        rabbit_user     => 'quantum',
        sql_connection  => "mysql://quantum:${password}@${dbserver}/quantum",
    }

    class { 'quantum::server':
        auth_password => $password,
        auth_host     => "${keystone}"
    }

    @@mysql::db { 'quantum':
        user     => 'quantum',
        password => "${password}",
        host     => "${ipaddress}",
        tag      => "${dbserver}"
    }

    @@rabbitmq_user { 'quantum':
        admin    => true,
        password => "${password}",
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}"
    }

    @@rabbitmq_user_permissions { "quantum@/":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        tag                  => "${amqpserver}"
    }

    @@keystone_user { 'quantum':
        ensure   => present,
        password => "${password}",
        email    => "quantum@localhost",
        tenant   => "services",
        tag      => "${keystone}"
    }

    @@keystone_user_role { "quantum@services":
        ensure  => present,
        roles   => 'admin',
        tag     => "${keystone}"
    }

    @@keystone_service { 'quantum':
        ensure      => present,
        type        => "network",
        description => "Quantum Networking Service",
        tag         => "${keystone}"
    }

    @@keystone_endpoint { "RegionOne/quantum":
        ensure       => present,
        public_url   => "http://${fqdn}:9696",
        admin_url    => "http://${fqdn}:9696",
        internal_url => "http://${fqdn}:9696",
        tag          => "${keystone}"
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::quantum_']
}
