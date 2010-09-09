package Mcsui::Clusters;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
	$self->mode_param(
		path_info => 2,
		param => 'rm'
	);
}

sub view_clusters : StartRunmode {
    my $self = shift;
    my $output = '';
    my @eclusters = $self->{'admin'}->getEntities(type => 'Cluster', hash => {});
    my $clusters = [];
    my $details = [];
	
    foreach my $n (@eclusters){
    	my $tmp = {};
	$tmp->{ID} = $n->getAttr(name => 'cluster_id');
	$tmp->{NAME} = $n->getAttr(name => 'cluster_name');
	$tmp->{STATE} = $n->getAttr(name => 'cluster_state');
	$tmp->{ACTIVE} = $n->getAttr('name' => 'active');
	push (@$clusters, $tmp);	
    }	
    foreach my $m (@eclusters){
	my $tmp = {};
	$tmp->{ID} = $m->getAttr(name => 'cluster_id');
	$tmp->{MIN_NODE} = $m->getAttr(name => 'cluster_min_node');
	$tmp->{MAX_NODE} = $m->getAttr(name => 'cluster_max_node');
	my $ekernel = $self->{'admin'}->getEntity(type =>'Kernel', id => $m->getAttr(name =>'kernel_id'));
	$tmp->{KERNEL} = $ekernel->getAttr(name => 'kernel_version')." ".$ekernel->getAttr(name => 'kernel_name');
	if ($m->getAttr(name => 'systemimage_id')){
		my $esystem = $self->{'admin'}->getEntity(type =>'Systemimage', id => $m->getAttr(name =>'systemimage_id'));
		$tmp->{SYSIMGNAME} =  $esystem->getAttr(name => 'systemimage_name');
	}else{
		$tmp->{SYSIMGNAME} = "";
	}
	push (@$details, $tmp);
    }

    my $tmpl =  $self->load_tmpl('view_clusters.tmpl');
	$tmpl->param('CLUSTERS' => $clusters);
	$tmpl->param('DETAILS' => $details);
    $tmpl->param('TITLE_PAGE' => "Clusters View");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param('SUBMENU_CLUSTERS' => 1);
	
	$output .= $tmpl->output();
        
    return $output;
}
sub form_addcluster : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl =$self->load_tmpl('form_addcluster.tmpl');
	my $output = '';
	$tmpl->param('TITLE_PAGE' => "Adding a Cluster");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MOTHERBOARDS' => 1);
	$tmpl->param($errors) if $errors;
	
	my @ekernels = $self->{'admin'}->getEntities(type => 'Kernel', hash => {});
	my @esystemimages = $self->{'admin'}->getEntities(type => 'Systemimage', hash => {});
	
	my $kmodels = [];
	foreach $k (@ekernels) {
		my $tmp = { ID => $k->getAttr( name => 'kernel_id'),
			NAME => join (' ',$k->getAttr(name => 'kernel_name'),$k->getAttr(name => 'kernel_version'))
		};
		push (@$kmodels, $tmp);	
	} 
	my $smodels = [];
	foreach $s (@esystemimages){
		my $tmp = { ID => $s->getAttr (name => 'systemimage_id'),
			NAME => $s->getAttr(name => 'systemimage_name')
		};
		push (@$smodels, $tmp);
	}

	$tmpl->param('KERNELS' => $kmodels);
	$tmpl->param('SYSTEMIMAGES' => $smodels);
	$output .= $tmpl->output();
	return $output;
}

sub form_removecluster : Runmode {
    my $self = shift;
    return 'you are on remove_cluster page';
}

1;
