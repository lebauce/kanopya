class kanopya::openstack::glance(
    $email,
    $database_name      = 'glance',
    $database_user      = 'glance',
    $database_password  = 'glance',
    $keystone_user      = 'glance',
    $keystone_password  = 'glance'
) {
    tag("kanopya::glance")

    $dbip = $components[glance][mysql][mysqld][ip]
    $dbserver = $components[glance][mysql][mysqld][tag]
    $keystone = $components[glance][keystone][keystone_admin][tag]
    $keystone_ip = $components[glance][keystone][keystone_admin][ip]

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    if ($components['glance']['master'] == 1) {
        @@mysql::db { "${database_name}":
            user     => "${database_user}",
            password => "${database_password}",
            host     => "${ipaddress}",
            grant    => ['all'],
            tag      => $dbserver,
        }

        @@keystone_user { "${keystone_user}":
            ensure   => present,
            password => "${keystone_password}",
            email    => "${email}",
            tenant   => 'services',
            tag      => $keystone
        }

        @@keystone_user_role { "${keystone_user}@services":
            ensure  => present,
            roles   => 'admin',
            tag     => $keystone
        }

        @@keystone_service { 'glance':
            ensure      => present,
            type        => 'image',
            description => "Openstack Image Service",
            tag         => $keystone
        }

        $glance_access_ip = $components[glance][access][image_api][ip]
        @@keystone_endpoint { "RegionOne/glance":
            ensure       => present,
            public_url   => "http://${glance_access_ip}:9292/v1",
            admin_url    => "http://${fqdn}:9292/v1",
            internal_url => "http://${fqdn}:9292/v1",
            tag          => $keystone
        }
    }
    else {
        @@database_user { "${database_user}@${ipaddress}":
            password_hash => mysql_password("${database_password}"),
            tag           => $dbserver
        }

        @@database_grant { "${database_user}@${ipaddress}/${database_name}":
            privileges => ['all'],
            tag        => $dbserver
        }
    }

    if ! defined(Exec['/usr/bin/glance-manage db_sync']) {
        exec { "/usr/bin/glance-manage db_sync":
            path => "/usr/bin:/usr/sbin:/bin:/sbin",
            user => "glance"
        }
    }

    class { 'glance::registry':
        auth_type         => 'keystone',
        bind_host         => $components[glance][listen][glance_registry][ip],
        keystone_tenant   => 'services',
        keystone_user     => $keystone_user,
        keystone_password => $keystone_password,
        sql_connection    => "mysql://${database_user}:${database_password}@${dbip}/${database_name}",
        before            => Exec['/usr/bin/glance-manage db_sync'],
        require           => Class['kanopya::openstack::repository']
    }

    class { 'glance::api':
        auth_type         => 'keystone',
        auth_port         => '35357',
        auth_host         => $keystone_ip,
        bind_host         => $components[glance][listen][image_api][ip],
        keystone_tenant   => 'services',
        keystone_user     => "${keystone_user}",
        keystone_password => "${keystone_password}",
        registry_host     => $components[glance][access][glance_registry][ip],
        sql_connection    => "mysql://${database_user}:${database_password}@${dbip}/${database_name}",
        before            => Exec['/usr/bin/glance-manage db_sync'],
        require           => Class['kanopya::openstack::repository']
    }

    class { 'glance::backend::file': }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::glance']

    if defined(Mount['/var/lib/glance/images']) {
        exec { 'chown glance:glance /var/lib/glance/images':
            subscribe => Mount['/var/lib/glance/images'],
            refreshonly => true
        }
    }
}
