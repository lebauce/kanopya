package Mcsui::Systemstatus;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_status : StartRunmode {
    my $self = shift;
    my $output = '';
    
    my $tmpl =  $self->load_tmpl('view_status.tmpl');
    $tmpl->param('TITLE_PAGE' => "System Status");
	$tmpl->param('MENU_SYSTEMSTATUS' => 1);
	$output .= $tmpl->output();
     
    return $output;   
}

sub view_executionqueue : Runmode {
	my $self = shift;
	my $output = '';
	    
    my $tmpl =  $self->load_tmpl('view_executionqueue.tmpl');
    $tmpl->param('TITLE_PAGE' => "Execution Queue");
	$tmpl->param('MENU_SYSTEMSTATUS' => 1);
		
	my $Operations = $self->{admin}->getOperations();
	$tmpl->param('OPERATIONS' => $Operations);
	$output .= $tmpl->output();
    
    return $output;   

}

1;
