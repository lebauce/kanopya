class kanopya::openstack::nova::controller(
    $admin_password,
    $dbserver,
    $amqpserver,
    $keystone,
    $email,
    $glance,
    $quantum,
    $keystone_user            = 'nova',
    $keystone_password        = 'nova',
    $cinder_keystone_user     = 'cinder',
    $cinder_keystone_password = 'cinder',
    $glance_keystone_user     = 'glance',
    $glance_keystone_password = 'glance',
    $glance_database_user     = 'glance',
    $glance_database_password = 'glance',
    $glance_database_name     = 'glance',
    $database_user            = 'nova',
    $database_password        = 'nova',
    $database_name            = 'nova',
    $rabbit_user              = 'nova',
    $rabbit_password          = 'nova',
    $rabbit_virtualhost       = '/'
) {
    tag("kanopya::novacontroller")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    exec { "/usr/bin/nova-manage db sync":
        path => "/usr/bin:/usr/sbin:/bin:/sbin",
    }

    if $rabbit_virtualhost != "/" {
        @@rabbitmq_vhost { "${rabbit_virtualhost}":
            ensure => present,
            provider => 'rabbitmqctl',
            tag => "${amqpserver}"
        }
    }

    @@rabbitmq_user { "${rabbit_user}":
        admin    => true,
        password => "${rabbit_password}",
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}",
    }

    @@rabbitmq_user_permissions { "${rabbit_user}@${rabbit_virtualhost}":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        tag                  => "${amqpserver}",
    }

    @@keystone_user { "${keystone_user}":
        ensure   => present,
        password => "${keystone_password}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}",
    }

    @@keystone_user_role { "${keystone_user}@services":
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

    @@mysql::db { "${database_name}":
        user     => "${database_user}",
        password => "${database_password}",
        host     => "${ipaddress}",
        grant    => ['all'],
        charset  => 'latin1',
        tag      => "${dbserver}",
    }

    @@database_user { "${database_user}@${fqdn}":
        password_hash => mysql_password("${database_password}"),
        tag           => "${dbserver}",
    }

    @@database_grant { "${database_user}@${fqdn}/${database_name}":
        privileges => ['all'] ,
        tag        => "${dbserver}"
    }

    class { 'nova::api':
        enabled          => true,
        admin_password   => "${admin_password}",
        auth_host        => $keystone,
        api_bind_address => $admin_ip,
        metadata_listen  => $admin_ip,
        require          => [ Exec["/usr/bin/nova-manage db sync"],
                              Class['kanopya::openstack::repository'] ]
    }

    class { 'cinder::api':
        keystone_auth_host => $keystone,
        keystone_tenant    => 'services',
        keystone_password  => "${cinder_keystone_password}",
        bind_host          => $admin_ip,
        require            => Exec['/usr/bin/cinder-manage db sync'],
    }

    class { 'glance::api':
        auth_type         => '',
        auth_port         => '35357',
        auth_host         => $keystone,
        bind_host         => $admin_ip,
        keystone_tenant   => 'services',
        keystone_user     => "${glance_keystone_user}",
        keystone_password => "${glance_keystone_password}",
        registry_host     => $glance,
        sql_connection    => "mysql://${glance_database_user}:${glance_database_password}@${dbserver}/${glance_database_name}",
        require           => [ Class['kanopya::openstack::repository'],
                               Exec['/usr/bin/glance-manage db_sync'] ]
    }

    nova_paste_api_ini {
        'filter:ratelimit/paste.filter_factor': value => "nova.api.openstack.compute.limits:RateLimitingMiddleware.factory";
        'filter:ratelimit/limits': value => '(POST, "*", .*, 100000, MINUTE);(POST, "*/servers", ^/servers, 500000, DAY);(PUT, "*", .*, 100000, MINUTE);(GET, "*changes-since*", .*changes-since.*, 3, MINUTE);(DELETE, "*", .*, 100000, MINUTE)';
    }

    if ! defined(Class['kanopya::openstack::nova::common']) {
        class { 'kanopya::openstack::nova::common':
            amqpserver         => "${amqpserver}",
            dbserver           => "${dbserver}",
            glance             => "${glance}",
            keystone           => "${keystone}",
            quantum            => "${quantum}",
            email              => "${email}",
            database_user      => "${database_user}",
            database_password  => "${database_password}",
            database_name      => "${database_name}",
            rabbit_user        => "${rabbit_user}",
            rabbit_password    => "${rabbit_password}",
            rabbit_virtualhost => "${rabbit_virtualhost}",
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

