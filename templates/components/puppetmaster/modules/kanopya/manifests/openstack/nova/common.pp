class kanopya::openstack::nova::common(
  $keystone           = 'localhost',
  $email              = 'nothing@nothing.com',
  $glance             = '127.0.0.1',
  $neutron            = undef,
  $sql_connection     = false,
  $rabbits            = [ '127.0.0.1' ],
  $rabbit_user        = 'nova',
  $rabbit_password    = 'nova',
  $rabbit_virtualhost = '/'
) {
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

  if ($neutron) {
    class { 'nova::network::neutron':
      neutron_admin_password    => "neutron",
      neutron_auth_strategy     => 'keystone',
      neutron_url               => "http://${neutron}:9696",
      neutron_admin_tenant_name => 'services',
      neutron_admin_auth_url    => "http://${keystone}:35357/v2.0",
      require                   => Class['kanopya::openstack::repository']
    }
  }
}
