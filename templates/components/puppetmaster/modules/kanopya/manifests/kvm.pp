class kanopya::kvm::service {
  service {
    'kvm':
      name => $operatingsystem ? {
        /(RedHat|CentOS|Fedora)/ => 'libvirtd',
        default                  => 'libvirt-bin'
      },
      ensure     => running,
      hasstatus  => true,
      hasrestart => true,
      enable     => true,
      require    => Class['kanopya::kvm::install'],
  }
  service {
    'dnsmasq':
      name       => 'dnsmasq',
      ensure     => stopped,
      hasstatus  => true,
      hasrestart => true,
      enable     => false,
  }
}

class kanopya::kvm::install {
  package {
    'kvm':
      name => $operatingsystem ? {
        /(RedHat|CentOS|Fedora)/ => 'libvirt',
        default                  => 'libvirt-bin'
      },
      ensure => present,
  }
}

class kanopya::kvm {
  include kanopya::kvm::install, kanopya::kvm::service
}
