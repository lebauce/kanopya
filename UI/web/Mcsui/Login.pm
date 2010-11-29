package Mcsui::Login;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub form_login : StartRunmode {
    my $self = shift;
    my $output = '';
    my $template = $self->load_tmpl('login.tmpl');
    $output .= $template->output();
    return $output;
}

sub process_login : Runmode {
	my $self = shift;
	# TODO manage user session...
	$self->redirect('/cgi/mcsui.cgi/overview');
}

sub process_logout : Runmode {
	my $self = shift;
	# TODO manage user session...
	$self->redirect('/cgi/mcsui.cgi/login/form_login');
}



1;
