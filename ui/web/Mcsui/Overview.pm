package Mcsui::Overview;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->{'menu'} = 'Dashboard';
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}

sub overview : StartRunmode {
	my $self = shift;
	my $tmpl =  $self->load_tmpl('overview.tmpl');
    
    $tmpl->param('titlepage' => 'Dashboard - Overview');
    $tmpl->param('mDashboard' => 1);
    $tmpl->param('submOverview' => 1);
    
    return $tmpl->output();   
}

1;