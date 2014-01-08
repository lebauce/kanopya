class kanopya::openstack::swift::storage(
  $swift_zone     = "zone",
  $secret         = "secret", 
  $object_port    = '6000',
  $container_port = '6001',
  $account_port   = '6002',
  $log_facility   = 'LOG_LOCAL2'
) {
  include 'ssh::server::install'

  if ! defined(Class['swift']) {
    class { 'swift':
      swift_hash_suffix => $secret,
      package_ensure    => latest,
    }
  }

  class { '::swift::storage':
    storage_local_net_ip => $ipaddress,
  }

  swift::storage::loopback { ['1', '2']:
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
 }

  Swift::Storage::Server {
    devices              => $devices,
    storage_local_net_ip => $ipaddress,
    mount_check          => $mount_check,
  }

  swift::storage::server { $account_port:
    type             => 'account',
    config_file_path => 'account-server.conf',
    pipeline         => $account_pipeline,
    log_facility     => $log_facility,
  }

  swift::storage::server { $container_port:
    type             => 'container',
    config_file_path => 'container-server.conf',
    pipeline         => $container_pipeline,
    log_facility     => $log_facility,
  }

  swift::storage::server { $object_port:
    type             => 'object',
    config_file_path => 'object-server.conf',
    pipeline         => $object_pipeline,
    log_facility     => $log_facility
  }

  @@ring_object_device { "${ipaddress}:6000/1":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_object_device { "${ipaddress}:${object_port}/2":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_container_device { "${ipaddress}:${container_port}/1":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_container_device { "${ipaddress}:${container_port}/2":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_account_device { "${ipaddress}:${account_port}/1":
    zone   => $swift_zone,
    weight => 1,
  }

  @@ring_account_device { "${ipaddress}:${account_port}/2":
    zone   => $swift_zone,
    weight => 1,
  }

  Swift::Ringsync<<||>>
}

