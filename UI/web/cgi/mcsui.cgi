#!/usr/bin/perl -w

use CGI::Application::Dispatch;
use lib '..';
CGI::Application::Dispatch->dispatch(
	prefix => 'Mcsui',
	args_to_new => { TMPL_PATH => '/workspace/mcs/UI/web/Mcsui/templates/' },
	default => 'Login',
	debug => 1,
	
);
