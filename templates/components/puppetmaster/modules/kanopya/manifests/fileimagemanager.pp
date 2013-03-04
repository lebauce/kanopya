class kanopya::fileimagemanager {
    package { 'libguestfs0':
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
    }
}
