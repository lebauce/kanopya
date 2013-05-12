class kanopya::openstack::nova::common($amqpserver, $dbserver, $glance, $keystone, $quantum, $email, $password) {
    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    class { 'nova':
        # set sql and rabbit to false so that the resources will be collected
        sql_connection     => "mysql://nova:${password}@${dbserver}/nova",
        rabbit_host        => "${amqpserver}",
        image_service      => 'nova.image.glance.GlanceImageService',
        glance_api_servers => "${glance}",
        rabbit_userid      => "nova",
        rabbit_password    => "nova"
    }

    class { 'nova::network::quantum':
        quantum_admin_password    => "quantum",
        quantum_auth_strategy     => 'keystone',
        quantum_url               => "http://${quantum}:9696",
        quantum_admin_tenant_name => 'services',
        quantum_admin_auth_url    => "http://${keystone}:35357/v2.0",
        require                   => Class['kanopya::openstack::repository']
    }
}
