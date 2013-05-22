class kanopya::openstack::cinder($rabbits, $dbpassword, $dbserver, $amqpserver, $rpassword, $kpassword, $email, $keystone) {
    tag("kanopya::cinder")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    class {'::cinder':
        rabbit_hosts    => $rabbits,
        sql_connection  => "mysql://cinder:${dbpassword}@${dbserver}/cinder",
        rabbit_userid   => 'cinder',
        rabbit_password => "${rpassword}",
    }

    class { 'cinder::api':
        keystone_tenant   => 'services',
        keystone_password => 'cinder',
        require           => Exec['/usr/bin/cinder-manage db sync'],
    }

    class { 'cinder::scheduler': }

    class { 'cinder::volume': }

    @@mysql::db { 'cinder':
        user     => 'cinder',
        password => "${dbpassword}",
        host     => "${ipaddress}",
        tag      => "${dbserver}"
    }

    @@rabbitmq_user { 'cinder':
        admin    => true,
        password => "${rpassword}",
        provider => 'rabbitmqctl',
        tag      => "${amqpserver}"
    }

    @@rabbitmq_user_permissions { "cinder@/":
        configure_permission => '.*',
        write_permission     => '.*',
        read_permission      => '.*',
        provider             => 'rabbitmqctl',
        tag                  => "${amqpserver}"
    }

    @@keystone_user { 'cinder':
        ensure   => present,
        password => "${kpassword}",
        email    => "${email}",
        tenant   => 'services',
        tag      => "${keystone}",
    }

    @@keystone_user_role { 'cinder@services':
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

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::cinder']
}
