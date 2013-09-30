class kanopya::openstack::swift::proxy($secret, $password) {
    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    if ! defined(Class['ssh::server::install']) {
        class { 'ssh::server::install': }
    }

    if ! defined(Class['swift']) {
        class { 'swift':
            swift_hash_suffix => $secret,
            package_ensure => latest,
        }
    }

    if ! defined(Class['::memcached']) {
        class { '::memcached':
            # listen_ip => '127.0.0.1',
        }
    }

    class { '::swift::proxy':
        proxy_local_net_ip => $ipaddress,
        pipeline => [
            'catch_errors',
            'healthcheck',
            'cache',
            'ratelimit',
            'swift3',
            's3token',
            'authtoken',
            'keystone',
            'proxy-server'
        ],
        account_autocreate => true,
        require => Class['swift::ringbuilder'],
    }

    class { [
        'swift::proxy::catch_errors',
        'swift::proxy::healthcheck',
        'swift::proxy::cache',
        'swift::proxy::swift3',
    ]: }

    class { 'swift::proxy::ratelimit':
        clock_accuracy => 1000,
        max_sleep_time_seconds => 60,
        log_sleep_time_seconds => 0,
        rate_buffer_seconds => 5,
        account_ratelimit => 0
    }

    class { 'swift::proxy::s3token':
        auth_host => $keystone,
        auth_port => '35357',
    }

    class { 'swift::proxy::keystone':
        operator_roles => ['admin', 'SwiftOperator'],
    }

    class { 'swift::proxy::authtoken':
        admin_user => 'swift',
        admin_tenant_name => 'services',
        admin_password => "${password}",
        auth_host => $swift_keystone_node,
    }

    Ring_object_device <<| |>>
    Ring_container_device <<| |>>
    Ring_account_device <<| |>>

    class { 'swift::ringbuilder':
        part_power => '18',
        replicas => '3',
        min_part_hours => 1,
        require => Class['swift'],
    }

    rsync::server::module { "swift_server":
        path => '/etc/swift', 
        lock_file => "/var/lock/swift_server.lock",
        uid => 'swift',
        gid => 'swift',
        max_connections => 10,
        read_only => true,
    }

    @@swift::ringsync { ['account', 'object', 'container']:
        ring_server => $ipaddress
    }

    class { 'swift::test_file':
        auth_server => $keystone,
        password => $password,
    }

    if ($components[swiftstorage][master] == 1) {
        @@keystone_user { 'swift':
            ensure   => present,
            password => 'swift',
            email    => 'swift@swift.com',
            tenant   => 'services',
            tag      => $components[swiftstorage][keystone][keystone_admin][tag]
        }

        @@keystone_user_role { "swift@services":
            ensure  => present,
            roles   => 'admin',
            require => Keystone_user['swift'],
            tag     => $components[swiftstorage][keystone][keystone_admin][tag]
        }

        @@keystone_service { 'swift':
            ensure      => present,
            type        => 'object-store',
            description => 'Openstack Object-Store Service',
            tag         => $components[swiftstorage][keystone][keystone_admin][tag]
        }

        $swift_access_ip = $components[swiftproxy][access][swiftproxy][ip]
        @@keystone_endpoint { "RegionOne/swift":
            ensure       => present,
            public_url   => "http://${swift_access_ip}:8080/v1/AUTH_%(tenant_id)s",
            admin_url    => "http://${fqdn}:8080/",
            internal_url => "http://${fqdn}:8080/v1/AUTH_%(tenant_id)s",
            tag          => $components[swiftstorage][keystone][keystone_admin][tag]
        }

        @@keystone_service { "swift_s3":
            ensure      => present,
            type        => 's3',
            description => 'Openstack S3 Service',
            tag         => $components[swiftstorage][keystone][keystone_admin][tag]
        }

        @@keystone_endpoint { "RegionOne/swift_s3":
            ensure       => present,
            public_url   => "http://${swift_access_ip}:8080",
            admin_url    => "http://${fqdn}:${port}",
            internal_url => "http://${fqdn}:${port}",
            tag          => $components[swiftstorage][keystone][keystone_admin][tag]
        }
    }
}

