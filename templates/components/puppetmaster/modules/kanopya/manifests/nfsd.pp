class kanopya::nfsd::service {
  service { 'nfsd':
      name => $operatingsystem ? {
        /(RedHat|CentOS|Fedora)/ => 'nfs',
        default => 'nfs-kernel-server'
      },
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      enable => true,
      require => Class['kanopya::nfsd::install'],
  }
}

class kanopya::nfsd::install {
  if $operationsystem !~ /RedHat|CentOS|Fedora/ {
    package { 'nfsd':
        name => 'nfs-kernel-server',
        ensure => present,
    }
  }
}

class kanopya::nfsd {
  include kanopya::nfs::install, kanopya::nfs::service
  include kanopya::nfsd::install, kanopya::nfsd::service

  file { '/nfsexports':
    ensure => 'directory',
  }
}

