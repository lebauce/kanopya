class kanopya::openstack::cinder::iscsi (
  $iscsi_ip_address      = "${ipaddress}",
  $volume_group          = 'cinder-volumes',
  $iscsi_helper          = 'tgtadm',
  $iscsi_backend_section = 'iscsi-backend'
) {

  tag("kanopya::cinder")

  include cinder::params

  cinder_config {
    "${iscsi_backend_section}/iscsi_helper":     value => $iscsi_helper;
    "${iscsi_backend_section}/volume_group":     value => $volume_group;
  }

  exec { 'apply-cinder-lvm-patch':
    command     => "sed -i -e s/\'IncomingUser/\'#IncomingUser/ /usr/lib/python2.7/dist-packages/cinder/volume/drivers/lvm.py",
    refreshonly => true,
    subscribe   => Package['cinder']
  }

  if($iscsi_ip_address) {
      cinder_config {
        "${iscsi_backend_section}/iscsi_ip_address": value => $iscsi_ip_address;
      }
  }

  case $iscsi_helper {
    'tgtadm': {
      package { 'tgt':
        name   => $::cinder::params::tgt_package_name,
        ensure => present,
      }

      if($::osfamily == 'RedHat') {
        file_line { 'cinder include':
          path => '/etc/tgt/targets.conf',
          line => "include /etc/cinder/volumes/*",
          match => '#?include /',
          require => Package['tgt'],
          notify => Service['tgtd'],
        }
      }

      service { 'tgtd':
        name    => $::cinder::params::tgt_service_name,
        ensure  => running,
        enable  => true,
        require => Class['cinder::volume'],
      }
    }

    default: {
      fail("Unsupported iscsi helper: ${iscsi_helper}.")
    }
  }

}
