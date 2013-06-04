class kanopya::openstack::nova::common(
    $amqpserver,
    $dbserver,
    $glance,
    $keystone,
    $quantum,
    $email,
    $database_user      = 'nova',
    $database_password  = 'nova',
    $database_name      = 'nova',
    $rabbit_user        = 'nova',
    $rabbit_password    = 'nova',
    $rabbit_virtualhost = '/'
) {
    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    class { 'nova':
        # set sql and rabbit to false so that the resources will be collected
        sql_connection      => "mysql://${database_user}:${database_password}@${dbserver}/${database_name}",
        image_service       => 'nova.image.glance.GlanceImageService',
        glance_api_servers  => "${glance}",
        rabbit_userid       => "${rabbit_user}",
        rabbit_password     => "${rabbit_password}",
        rabbit_host         => "${amqpserver}",
        rabbit_virtual_host => "${rabbit_virtualhost}"
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
