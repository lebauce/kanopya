package KanopyaUI::CGI;
use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;

use Administrator;

sub cgiapp_init {
	my $self = shift;
}


sub cgiapp_prerun {
	my $self = shift;
	my $eid = $self->session->param('EID');
	if(not $eid) {
		$self->session_delete;
		$self->redirect('/cgi/kanopya.cgi/login/form_login');
	} else {
		$ENV{EID} = $eid;
		$self->{'admin'} = Administrator->new();
	}
}

1;