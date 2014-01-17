class kanopya::iscsitarget::params {
  case $operatingsystem {
    /(?i)(debian|ubuntu)/ : {
      $iscsitarget_service_name = 'iscsitarget'
      $iscsitarget_package_name = 'iscsitarget'
    }
    /(?i)(redhat|centos)/ : {
      $iscsitarget_service_name = 'iscsi-target'
      $iscsitarget_package_name = 'iscsitarget'
    }
    default : {
      fail("Unsupported operatingsystem : ${operatingsystem}. Only Debian, Ubuntu, RedHat and CentOS are supported")
    }
  }
}

class kanopya::iscsitarget inherits kanopya::iscsitarget::params {
  package { 'iscsitarget':
    name => $kanopya::iscsitarget::params::iscsitarget_package_name,
    ensure => present,
  }

  service { $kanopya::iscsitarget::params::iscsitarget_service_name:
    name     => $kanopya::iscsitarget::params::iscsitarget_service_name,
    ensure   => running,
    enable   => true,
    require  => Package['iscsitarget'],
  }

  case $::operatingsystem {
    /(?i)(debian|ubuntu)/ : {
      file { '/etc/default/iscsitarget':
        content => "ISCSITARGET_ENABLE=true\n",
      }

      package { 'iscsitarget-dkms':
        before => Package['iscsitarget'],
        ensure => present,
      }
    }
  }
}
