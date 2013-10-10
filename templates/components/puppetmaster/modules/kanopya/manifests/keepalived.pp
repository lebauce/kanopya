class kanopya::keepalived(
    email,
    smtp_server
) {
	class { 'concat::setup': }
	class { '::keepalived':
		email => "${email}",
		smtp_server => "${smtp_server}"
	}
}
