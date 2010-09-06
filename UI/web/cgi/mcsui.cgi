#!/usr/bin/perl -w

use lib qw(/workspace/mcs/UI/web /workspace/mcs/Administrator/Lib);
use CGI::Application::Dispatch;
use Log::Log4perl;

Log::Log4perl->init('/workspace/mcs/UI/web/log.conf');
use Administrator;

CGI::Application::Dispatch->dispatch(
	prefix => 'Mcsui',
	args_to_new => { 
		TMPL_PATH => '/workspace/mcs/UI/web/Mcsui/templates/',
	},
	default => 'Login',
	debug => 1,
);




