class kanopya::openstack::quantum::server($amqpserver, $dbserver, $keystone, $password, $email, $bridge_flat, $bridge_vlan) {
    tag("kanopya::quantum")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    class { '::quantum':
        rabbit_password => "${password}",
        rabbit_host     => "${amqpserver}",
        rabbit_user     => 'quantum',
    }

    class { '::quantum::server':
        auth_password => $password,
        auth_host     => "${keystone}",
        require       => Class['kanopya::openstack::repository']
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
        email    => "${email}",
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

    class { 'quantum::plugins::ovs':
        sql_connection      => "mysql://quantum:${password}@${dbserver}/quantum",
        tenant_network_type => 'vlan',
        network_vlan_ranges => 'physnetflat,physnetvlan:1:4094',
        require             => Class['kanopya::openstack::repository']
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::quantum::server']
}
