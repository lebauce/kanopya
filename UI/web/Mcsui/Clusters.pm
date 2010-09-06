package Mcsui::Clusters;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
}

sub view_clusters : StartRunmode {
    my $self = shift;
    my $output = '';
    
    my $tmpl =  $self->load_tmpl('view_clusters.tmpl');
    $tmpl->param('TITLE_PAGE' => "Clusters View");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param('SUBMENU_CLUSTERS' => 1);
	
	$output .= $tmpl->output();
        
    return $output;
}

sub add_clusters : Runmode {
    my $self = shift;
    return 'you are on add_cluster page';
}

sub remove_cluster : Runmode {
    my $self = shift;
    return 'you are on remove_cluster page';
}

1;
