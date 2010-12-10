package Mcsui::Permissions;
use Data::Dumper;
use base 'CGI::Application';
use Log::Log4perl "get_logger";
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use strict;
use warnings;


my $log = get_logger("administrator");
my $closewindow = "<script type=\"text/javascript\">window.opener.location.reload();window.close();</script>";

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}
