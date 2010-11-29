package Mcsui::Users;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;

sub setup {
	my $self = shift;
	my $tmpl_path = [
	'/workspace/mcs/UI/web/Mcsui/templates',
	'/workspace/mcs/UI/web/Mcsui/templates/Users'];
	$self->tmpl_path($tmpl_path);
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub users_list : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('view_users.tmpl');
    $tmpl->param('titlepage' => "Systems - System images");
    $tmpl->param('mSettings' => 1);
	$tmpl->param('submUsers' => 1);
	
	return $tmpl->output();
}

1;