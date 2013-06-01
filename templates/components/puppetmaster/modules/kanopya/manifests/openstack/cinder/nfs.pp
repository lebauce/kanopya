class kanopya::openstack::cinder::nfs (
  $nfs_servers = [],
  $nfs_mount_options = undef,
  $nfs_disk_util = undef,
  $nfs_sparsed_volumes = undef,
  $nfs_mount_point_base = undef,
  $nfs_backend_section = "nfs-backend",
  $nfs_shares_config = "/etc/cinder/shares.conf"
) {

  tag("kanopya::cinder")

  file {$nfs_shares_config:
    content => join($nfs_servers, "\n"),
    require => Package['cinder'],
    notify  => Service['cinder-volume']
  }

  cinder_config {
    "${nfs_backend_section}/volume_driver":        value =>
      'cinder.volume.drivers.nfs.NfsDriver';
    "${nfs_backend_section}/nfs_shares_config":    value => $nfs_shares_config;
    "${nfs_backend_section}/nfs_mount_options":    value => $nfs_mount_options;
    "${nfs_backend_section}/nfs_disk_util":        value => $nfs_disk_util;
    "${nfs_backend_section}/nfs_sparsed_volumes":  value => $nfs_sparsed_volumes;
    "${nfs_backend_section}/nfs_mount_point_base": value => $nfs_mount_point_base;
  }

  if ! defined (Class['kanopya::nfs']) {
      class { 'kanopya::nfs': }
  }

  file { "/tmp/0001-Use-the-local-configuration-in-the-nfs-drivers.patch":
      source => "puppet:///modules/kanopya/0001-Use-the-local-configuration-in-the-nfs-drivers.patch",
      notify => Exec["apply-cinder-patch"],
  }

  exec {"apply-cinder-patch":
      command     => "patch -d /usr/lib/python2.7/dist-packages/ -p1 < /tmp/0001-Use-the-local-configuration-in-the-nfs-drivers.patch",
      refreshonly => true,
  }
}
