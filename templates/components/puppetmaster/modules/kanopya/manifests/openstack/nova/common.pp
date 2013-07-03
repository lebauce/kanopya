class kanopya::openstack::nova::common(
    $keystone,
    $email,
    $glance             = '127.0.0.1',
    $quantum            = undef,
    $sql_connection     = false,
    $rabbits            = [ '127.0.0.1' ],
    $rabbit_user        = 'nova',
    $rabbit_password    = 'nova',
    $rabbit_virtualhost = '/'
) {
    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    class { 'nova':
        # set sql and rabbit to false so that the resources will be collected
        sql_connection      => $sql_connection,
        image_service       => 'nova.image.glance.GlanceImageService',
        glance_api_servers  => "http://${glance}:9292",
        rabbit_userid       => $rabbit_user,
        rabbit_password     => $rabbit_password,
        rabbit_hosts        => $rabbits,
        rabbit_virtual_host => $rabbit_virtualhost
    }

    if ($quantum) {
        class { 'nova::network::quantum':
            quantum_admin_password    => "quantum",
            quantum_auth_strategy     => 'keystone',
            quantum_url               => "http://${quantum}:9696",
            quantum_admin_tenant_name => 'services',
            quantum_admin_auth_url    => "http://${keystone}:35357/v2.0",
            require                   => Class['kanopya::openstack::repository']
        }
    }
}
