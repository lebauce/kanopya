class kanopya::tftpd(
  $tftpdir = "/var/lib/kanopya/tftp"
) {
  file { $tftpdir:
    ensure => directory,
  }

  class { 'tftp':
    directory => $tftpdir,
    address   => '0.0.0.0',
  }
}
