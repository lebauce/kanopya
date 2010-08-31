package Mcsui::Login;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;


sub setup {
	my $self = shift;
	$self->tmpl_path('/home/thom/mcsweb/Mcsui/templates');
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
}

sub login : StartRunmode {
    my $self = shift;
    my $output = '';
    my $template = $self->load_tmpl('login.tmpl');
    $output .= $template->output();
    return $output;
}



1;
