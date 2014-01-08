class kanopya::openstack::quantum::common(
  $rabbit_user        = "quantum",
  $rabbit_password    = "quantum",
  $rabbit_hosts       = [ "localhost" ],
  $rabbit_virtualhost = "/"
) {
  if has_key($components, 'quantum') {
    $bind_address = $components[quantum][listen][quantum][ip]
  } else {
    $bind_address = '0.0.0.0'
  }

  class { 'quantum':
    rabbit_password     => "${rabbit_password}",
    rabbit_hosts        => $rabbit_hosts,
    rabbit_user         => "${rabbit_user}",
    rabbit_virtual_host => "${rabbit_virtualhost}",
    bind_host           => $bind_address
  }
}
