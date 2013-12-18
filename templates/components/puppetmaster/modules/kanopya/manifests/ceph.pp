class kanopya::ceph(
  $fsid            = 0,
  $cluster_network = "10.0.0.0/24",
  $public_network  = "10.1.0.0/24"
) {
  include ceph::apt::ceph

  class { 'ceph::conf':
    fsid            => "${fsid}",
    auth_type       => 'cephx',
    cluster_network => $cluster_network,
    public_network  => $public_network,
  }
}

class kanopya::ceph::mon($mon_id, $mon_secret) {
  tag("kanopya::cephmon")

  ceph::mon { $mon_id:
    monitor_secret => $mon_secret,
    mon_addr       => "${ipaddress}"
  }

  if $mon_id == 0 and !empty($::ceph_admin_key) {
    @@ceph::key { 'admin':
      secret       => $::ceph_admin_key,
      keyring_path => '/etc/ceph/keyring',
    }
  }

  Class['kanopya::ceph'] -> Class['kanopya::ceph::mon']
}

class kanopya::ceph::osd($devices) {
  tag("kanopya::cephosd")

  class { '::ceph::osd' :
    public_address  => "${ipaddress}",
    cluster_address => "${ipaddress}",
  }

  Class['kanopya::ceph'] -> Class['kanopya::ceph::osd']

  Ceph::Key <<| title == 'admin' |>>

  create_resources('ceph::osd::device', $devices)
}
