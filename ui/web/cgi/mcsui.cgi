#!/usr/bin/perl -w

use lib qw(/opt/kanopya/ui/web /opt/kanopya/lib/administrator /opt/kanopya/lib/common);
use CGI::Fast();
use CGI::Application::Dispatch;
use Log::Log4perl;

Log::Log4perl->init('/opt/kanopya/conf/log.conf');
use Administrator;


while(my $q = new CGI::Fast) {

    CGI::Application::Dispatch->dispatch(
	prefix => 'Mcsui',
	args_to_new => { 
		TMPL_PATH => '/opt/kanopya/ui/web/Mcsui/templates/',
		QUERY => $q
	},
	default => 'Login',
	debug => 1,
     );
}



