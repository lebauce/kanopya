class kanopya::keepalived(
  $email       = "nothing@nothing.com",
  $smtp_server = "127.0.0.1",
  $members     = [],
  $instances   = []
) {
  include 'concat::setup'

  class { '::keepalived':
    email       => "${email}",
    smtp_server => "${smtp_server}"
  }

  keepalived::vrrp_sync_group { 'VG1':
    members => $members
  }

  create_resources('keepalived::vrrp_instance', $instances)
}