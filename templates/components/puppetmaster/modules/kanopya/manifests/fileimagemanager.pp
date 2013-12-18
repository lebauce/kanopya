class kanopya::fileimagemanager {
  package { 'libguestfs':
    name => $operatingsystem ? {
      /(RedHat|CentOS|Fedora)/ => [ 'libguestfs', 'libguestfs-tools', 'qemu-img' ],
      default => [ 'libguestfs0', 'guestmount', 'qemu-utils', 'libguestfs-tools' ]
    },
    audit  => all,
    ensure => present,
    notify => Exec['update-guestfs-appliance']
  }

  exec { 'update-guestfs-appliance':
    path        => "/usr/bin:/usr/sbin:/bin:/sbin",
    refreshonly => true,
    subscribe   => Package['libguestfs'],
    require     => Package['libguestfs'],
    command     => $operatingsystem ? {
      /(RedHat|CentOS|Fedora)/ => 'true',
      default                  => 'update-guestfs-appliance'
    }
  }
}
