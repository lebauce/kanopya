class kanopya::openstack::nova::compute(
    $amqpserver,
    $dbserver,
    $glance,
    $keystone,
    $quantum,
    $email,
    $libvirt_type,
    $bridge_uplinks,
    $rabbit_user        = 'nova',
    $rabbit_password    = 'nova',
    $rabbit_virtualhost = '/'
) {
    tag("kanopya::novacompute")

    if ! defined(Class['kanopya::openstack::repository']) {
        class { 'kanopya::openstack::repository': }
    }

    file { "/run/iscsid.pid":
        content => "1",
    }

    if ! defined(Class['kanopya::openstack::nova::common']) {
        class { 'kanopya::openstack::nova::common':
            amqpserver         => "${amqpserver}",
            dbserver           => "${dbserver}",
            glance             => "${glance}",
            keystone           => "${keystone}",
            quantum            => "${quantum}",
            email              => "${email}",
            rabbit_user        => "${rabbit_user}",
            rabbit_password    => "${rabbit_password}",
            rabbit_virtualhost => "${rabbit_virtualhost}"
        }
    }

    class { '::nova::compute':
        enabled => true,
        require => Class['kanopya::openstack::repository']
    }

    class { 'nova::compute::quantum':
        libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver',
        require            => Class['kanopya::openstack::repository']
    }

    class { 'nova::compute::libvirt':
        libvirt_type      => "${libvirt_type}",
        migration_support => true,
        vncserver_listen  => '0.0.0.0',
        require           => Class['kanopya::openstack::repository']
    }

    class { 'quantum::agents::ovs':
        integration_bridge  => 'br-int',
        bridge_mappings     => [ 'physnetflat:br-flat', 'physnetvlan:br-vlan' ],
        bridge_uplinks      => $bridge_uplinks,
        require             => Class['kanopya::openstack::repository']
    }

    class { 'quantum::client':
    }

    if ! defined(Class['kanopya::openstack::quantum::common']) {
        class { 'kanopya::openstack::quantum::common':
            rabbit_host        => "${amqpserver}",
            rabbit_user        => "${rabbit_user}",
            rabbit_password    => "${rabbit_password}",
            rabbit_virtualhost => "${rabbit_virtualhost}"
        }
    }

    Class['kanopya::openstack::repository'] -> Class['kanopya::openstack::nova::compute']

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
