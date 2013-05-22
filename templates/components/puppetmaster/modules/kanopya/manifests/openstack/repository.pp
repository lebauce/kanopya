class kanopya::openstack::repository {
    if $operatingsystem =~ /(?i)(ubuntu)/ {
        package { 'ubuntu-cloud-keyring':
            name => 'ubuntu-cloud-keyring',
            ensure => present,
        }
    }
}
