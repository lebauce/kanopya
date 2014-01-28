class kanopya::openstack::neutron::common(
  $rabbit_user        = "neutron",
  $rabbit_password    = "neutron",
  $rabbit_hosts       = [ "localhost" ],
  $rabbit_virtualhost = "/"
) {
  if has_key($components, 'neutron') {
    $bind_address = $components[neutron][listen][neutron][ip]
  } else {
    $bind_address = '0.0.0.0'
  }

  class { 'neutron':
    rabbit_password     => "${rabbit_password}",
    rabbit_hosts        => $rabbit_hosts,
    rabbit_user         => "${rabbit_user}",
    rabbit_virtual_host => "${rabbit_virtualhost}",
    bind_host           => $bind_address
  }
}
