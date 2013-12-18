class kanopya::openiscsi(
  $initiatorname = ""
) {
  file { '/etc/iscsi/initiatorname.iscsi':
    content => "InitiatorName=${initiatorname}\n",
    require => Package['open-iscsi']
  }

  package { 'open-iscsi':
    ensure => present,
    name   => $operatingsystem ? {
      /(?i)(centos|redhat|fedora)/ => 'iscsi-initiator-utils',
      default                      => 'open-iscsi',
    },
  }
}
