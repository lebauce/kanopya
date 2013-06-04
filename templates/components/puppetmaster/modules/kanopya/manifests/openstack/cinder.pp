class kanopya::openstack::cinder(
    $rabbits,
    $dbserver,
    $amqpserver,
    $email,
    $keystone,
    $database_name      = "cinder",
    $database_user      = "cinder",
    $database_password  = "cinder",
    $keystone_user      = "cinder",
    $keystone_password  = "cinder",
    $rabbit_password    = "cinder",
    $rabbit_user        = "cinder",
    $rabbit_virtualhost = "/"
) {
    tag("kanopya::cinder")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    class { '::cinder':
        rabbit_hosts        => $rabbits,
        sql_connection      => "mysql://${database_user}:${database_password}@${dbserver}/${database_name}",
        rabbit_userid       => "${rabbit_user}",
        rabbit_password     => "${rabbit_password}",
        rabbit_virtual_host => "${rabbit_virtualhost}"
    }

    class { 'cinder::api':
        keystone_tenant   => 'services',
        keystone_password => "${keystone_password}",
        require           => Exec['/usr/bin/cinder-manage db sync'],
    }

    class { 'cinder::scheduler': }

    class { 'cinder::volume': }

    @@mysql::db { "${database_name}":
        user     => "${database_user}",
        password => "${database_password}",
        host     => "${ipaddress}",
        tag      => "${dbserver}"
    }

    @@rabbitmq_user { "${rabbit_user}":
        admin    => true,
        password => "${rabbit_password}",
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}"
    }

    @@rabbitmq_user_permissions { "${rabbit_user}@${rabbit_virtualhost}":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        tag                  => "${amqpserver}"
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

    @@keystone_service { 'cinder':
        ensure      => present,
        type        => "volume",
        description => "Cinder Volume Service",
        tag         => "${keystone}"
    }

    @@keystone_endpoint { "RegionOne/cinder":
        ensure       => present,
        public_url   => "http://${fqdn}:8776/v1/\$(tenant_id)s",
        admin_url    => "http://${fqdn}:8776/v1/\$(tenant_id)s",
        internal_url => "http://${fqdn}:8776/v1/\$(tenant_id)s",
        tag          => "${keystone}"
    }

    exec { "/usr/bin/cinder-manage db sync":
        path => "/usr/bin:/usr/sbin:/bin:/sbin",
    }

    cinder_config {
        "DEFAULT/enabled_backends": value => "nfs-backend,iscsi-backend";
        "DEFAULT/nfs_mount_options": value => "rw"
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::cinder']
}
