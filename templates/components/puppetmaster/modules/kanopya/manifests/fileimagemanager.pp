class kanopya::fileimagemanager {
    package { 'libguestfs0':
        audit => all,
        name => 'libguestfs0',
        ensure => present,
    }

    package { 'guestmount':
        name => 'guestmount',
        ensure => present,
    }

    package { 'qemu-utils':
        name => 'qemu-utils',
        ensure => present,
    }

    package { 'libguestfs-tools':
        name => 'libguestfs-tools',
        ensure => present,
        notify => Exec['update-guestfs-appliance']
    }

    exec { 'update-guestfs-appliance':
        path => "/usr/bin:/usr/sbin:/bin:/sbin",
        refreshonly => true,
        subscribe => Package['libguestfs0'],
        require => Package['libguestfs0'],
    }
}
