class kanopya::openssh {
  package {
    'openssh':
      ensure => present,
      name   => $operatingsystem ? {
        default => 'openssh-server'
      },
  }

  service {
    'openssh':
      name       => $operatingsystem ? {
        /(RedHat|CentOS|Fedora)/ => 'sshd',
        default                  => 'ssh'
      },
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      enable     => true,
      require    => Package['openssh'],
  }
}

