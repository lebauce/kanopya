class kanopya::fileimagemanager {
  $libguestfs_packages = $operatingsystem ? {
    /(RedHat|CentOS|Fedora)/ => [
      'libguestfs',
      'libguestfs-tools',
      'qemu-img'
    ],
    default                  => [
      'libguestfs0',
      'guestmount',
      'qemu-utils',
      'libguestfs-tools'
    ]
  }

  package { $libguestfs_packages:
    audit  => all,
    ensure => present,
    notify => Exec['update-guestfs-appliance'],
    before => Exec['update-guestfs-appliance'],
  }

  exec { 'update-guestfs-appliance':
    path        => "/usr/bin:/usr/sbin:/bin:/sbin",
    refreshonly => true,
    subscribe   => Package[$libguestfs_packages],
    require     => Package[$libguestfs_packages],
    command     => $operatingsystem ? {
      /(RedHat|CentOS|Fedora)/ => 'true',
      default                  => 'update-guestfs-appliance'
    }
  }
}
