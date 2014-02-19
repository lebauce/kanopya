class kanopya::openstack::nova::compute(
  $email              = 'nothing@nothing.com',
  $libvirt_type       = 'kvm',
  $bridge_uplinks     = 'eth1',
  $rabbit_user        = 'nova',
  $rabbit_password    = 'nova',
  $rabbit_virtualhost = '/'
) {
  tag("kanopya::novacompute")

  $amqpserver = $components[novacompute][amqp][amqp][tag]
  $rabbits = $components[novacompute][amqp][nodes]
  $keystone_ip = $components[novacompute][keystone][keystone_admin][ip]

  if has_key($components[novacompute], 'neutron') {
    $neutron = $components[novacompute][neutron][neutron][ip]
  } else {
    $neutron = undef
  }

  if has_key($components[novacompute], 'glance') {
    $glance_registry = $components[novacompute][glance][glance_registry][ip]
  } else {
    $glance_registry = undef
  }

  if ! defined(Class['kanopya::openstack::repository']) {
    class { 'kanopya::openstack::repository':
      stage => 'system',
    }
  }

  file { "/run/iscsid.pid":
    content => "1",
  }

  if ! defined(Class['kanopya::openstack::nova::common']) {
    class { 'kanopya::openstack::nova::common':
      keystone           => $keystone_ip,
      email        => $email,
      glance       => $glance_registry,
      neutron      => $neutron,
      rabbits      => $rabbits,
      rabbit_user        => $rabbit_user,
      rabbit_password    => $rabbit_password,
      rabbit_virtualhost => $rabbit_virtualhost
    }
  }

  class { '::nova::compute':
    enabled                       => true,
    vnc_enabled                   => true,
    vncserver_proxyclient_address => $admin_ip,
    vncproxy_host                 => $keystone,
    require                       => Class['kanopya::openstack::repository']
  }

  class { 'nova::compute::neutron':
    libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver',
    require            => Class['kanopya::openstack::repository']
  }

  class { 'nova::compute::libvirt':
    libvirt_type      => "${libvirt_type}",
    migration_support => true,
    vncserver_listen  => '0.0.0.0',
    require           => Class['kanopya::openstack::repository']
  }

  class { 'neutron::agents::ovs':
    integration_bridge  => 'br-int',
    bridge_mappings     => [ 'physnetflat:br-flat' ],
    bridge_uplinks      => $bridge_uplinks,
    require             => Class['kanopya::openstack::repository']
  }

  class { 'neutron::client':
  }
  
  class { 'neutron::agents::dhcp':
  }

  if ! defined(Class['kanopya::openstack::neutron::common']) {
    class { 'kanopya::openstack::neutron::common':
      rabbit_hosts       => $rabbits,
      rabbit_user        => "${rabbit_user}",
      rabbit_password    => "${rabbit_password}",
      rabbit_virtualhost => "${rabbit_virtualhost}"
    }
  }

  Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::nova::compute']

  if ! defined(Class['kanopya::nfs']) {
    class { 'kanopya::nfs': }
  }

  if defined(Mount['/var/lib/nova/instances']) {
    exec { 'chmod 777 /var/lib/nova/instances':
      subscribe   => Mount['/var/lib/nova/instances'],
      refreshonly => true
    }
  }

  nova_config {
    'DEFAULT/nfs_mount_options': value => 'nolock';
  }
}
