class kanopya::openstack::nova::controller($password, $dbserver, $amqpserver, $keystone, $email, $glance, $quantum) {
    tag("kanopya::novacontroller")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    exec { "/usr/bin/nova-manage db sync":
        path => "/usr/bin:/usr/sbin:/bin:/sbin",
    }

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

    @@mysql::db { 'nova':
            user     => 'nova',
            password => "${password}",
            host     => "${ipaddress}",
            grant    => ['all'],
            charset  => 'latin1',
            tag      => "${dbserver}",
    }

    @@database_user { "nova@${fqdn}":
        password_hash => mysql_password("${password}"),
        tag           => "${dbserver}",
    }

    @@database_grant { "nova@${fqdn}/nova":
        privileges => ['all'] ,
        tag        => "${dbserver}"
    }

    class { 'nova::api':
        enabled        => true,
        admin_password => "${password}",
        auth_host      => "${keystone}",
        require        => [ Exec["/usr/bin/nova-manage db sync"],
                            Class['kanopya::openstack::repository'] ]
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

    class { 'nova::scheduler':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::objectstore':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::cert':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::vncproxy':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::consoleauth':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::conductor':
        enabled => true
    }

    nova_config {
        'DEFAULT/ram_allocation_ratio': value => '100';
        'DEFAULT/cpu_allocation_ratio': value => '100'
    }

    $inf = 100000
    class { 'nova::quota':
        quota_instances                       => $inf,
        quota_cores                           => $inf,
        quota_ram                             => $inf,
        quota_volumes                         => $inf,
        quota_gigabytes                       => $inf,
        quota_floating_ips                    => $inf,
        quota_metadata_items                  => $inf,
        quota_max_injected_files              => $inf,
        quota_max_injected_file_content_bytes => $inf,
        quota_max_injected_file_path_bytes    => $inf,
        quota_security_groups                 => $inf,
        quota_security_group_rules            => $inf,
        quota_key_pairs                       => $inf
    }

    if defined(Class['kanopya::apache']) {
        class { 'openstack::horizon':
            secret_key => 'dummy_secret_key'
        }
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::nova::controller']
}

