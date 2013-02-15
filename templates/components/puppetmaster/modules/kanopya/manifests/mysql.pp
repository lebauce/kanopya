class kanopya::mysql {
	Mysql::Db <<| tag == "${fqdn}" |>>
	Database_user <<| tag == "${fqdn}" |>>
	Database_grant <<| tag == "${fqdn}" |>>
}

