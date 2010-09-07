package Mcsui::Login;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub login : StartRunmode {
    my $self = shift;
    my $output = '';
    my $template = $self->load_tmpl('login.tmpl');
    $output .= $template->output();
    return $output;
}



1;
