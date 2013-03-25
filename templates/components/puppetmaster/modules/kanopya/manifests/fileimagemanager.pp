class kanopya::fileimagemanager {
    package { 'libguestfs':
        audit => all,
        name => $operatingsystem ? {
            /(Red Hat|CentOS|Fedora)/ => [ 'libguestfs', 'libguestfs-tools', 'qemu-img' ],
            default => [ 'libguestfs0', 'guestmount', 'qemu-utils', 'libguestfs-tools' ]
        },
        ensure => present,
        notify => Exec['update-guestfs-appliance']
    }

    exec { 'update-guestfs-appliance':
        path => "/usr/bin:/usr/sbin:/bin:/sbin",
        refreshonly => true,
        subscribe => Package['libguestfs'],
        require => Package['libguestfs'],
        command => $operatingsystem ? {
            /(Red Hat|CentOS|Fedora)/ => 'true',
            default => 'update-guestfs-appliance'
        }
    }
}
