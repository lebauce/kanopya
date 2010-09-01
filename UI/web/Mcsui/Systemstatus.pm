package Mcsui::Systemstatus;
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

sub view_status : StartRunmode {
    my $self = shift;
    my $output = '';
    
    my $tmpl =  $self->load_tmpl('view_status.tmpl');
    $tmpl->param('TITLE_PAGE' => "System Status");
	$tmpl->param('MENU_SYSTEMSTATUS' => 1);
	
	$output .= $tmpl->output();
        
    return $output;
    
}



1;
