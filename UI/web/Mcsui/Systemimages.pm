package Mcsui::Systemimages;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
}

sub view_systemimages : StartRunmode {
    my $self = shift;
    my $output = '';
    
    my $tmpl =  $self->load_tmpl('view_systemimages.tmpl');
    $tmpl->param('TITLE_PAGE' => "System images View");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param('SUBMENU_SYSTEMIMAGES' => 1);
	
	$tmpl->param('USERID' => 1234);
	
	$output .= $tmpl->output();
        
    return $output;	
    
}


1;
