class kanopya::openstack::nova::compute($amqpserver, $dbserver, $glance, $keystone,
                           $quantum, $email, $password, $libvirt_type,
                           $qpassword, $bridge_uplinks) {
    tag("kanopya::novacompute")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    file { "/run/iscsid.pid":
        content => "1",
    }

    if ! defined(Class['kanopya::openstack::nova::common']) {
        class { 'kanopya::openstack::nova::common':
            amqpserver => "${amqpserver}",
            dbserver   => "${dbserver}",
            glance     => "${glance}",
            keystone   => "${keystone}",
            quantum    => "${quantum}",
            email      => "${email}",
            password   => "${password}"
        }
    }

    class { '::nova::compute':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::compute::quantum':
        libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver',
        require            => Class['kanopya::openstack::repository']
    }

    class { 'nova::compute::libvirt':
        libvirt_type      => "${libvirt_type}",
        migration_support => true,
        vncserver_listen  => '0.0.0.0',
        require           => Class['kanopya::openstack::repository']
    }

    if ! defined(Class['nova::api']) {
        class { 'nova::api':
            enabled        => true,
            admin_password => "${password}",
            auth_host      => "${keystone}",
            require        => Class['kanopya::openstack::repository']
        }

        nova_paste_api_ini {
            'filter:ratelimit/paste.filter_factor': value => "nova.api.openstack.compute.limits:RateLimitingMiddleware.factory";
            'filter:ratelimit/limits': value => '(POST, "*", .*, 100000, MINUTE);(POST, "*/servers", ^/servers, 500000, DAY);(PUT, "*", .*, 100000, MINUTE);(GET, "*changes-since*", .*changes-since.*, 3, MINUTE);(DELETE, "*", .*, 100000, MINUTE)';
        }
    }

    @@database_user { "nova@${ipaddress}":
        password_hash => mysql_password("${password}"),
        tag           => "${dbserver}",
    }

    @@database_grant { "nova@${ipaddress}/nova":
        privileges => ['all'] ,
        tag        => "${dbserver}"
    }

    class { 'quantum::agents::ovs':
        integration_bridge  => 'br-int',
        bridge_mappings     => [ 'physnetflat:br-flat', 'physnetvlan:br-vlan' ],
        bridge_uplinks      => $bridge_uplinks,
        require             => Class['kanopya::openstack::repository']
    }

    class { 'quantum::client':
    }

    class { 'quantum':
        rabbit_password => "${qpassword}",
        rabbit_host     => "${amqpserver}",
        rabbit_user     => 'quantum'
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::nova::compute']
}
