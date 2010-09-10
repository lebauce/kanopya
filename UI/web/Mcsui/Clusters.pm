package Mcsui::Clusters;
use base 'CGI::Application';
use Log::Log4perl "get_logger";
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;

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
	my $log = get_logger('administrator');
	my $tmpl =$self->load_tmpl('form_addcluster.tmpl');
	my $output = '';
	$tmpl->param('TITLE_PAGE' => "Adding a Cluster");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	$tmpl->param('SUBMENU_CLUSTERS' => 1);
	$tmpl->param($errors) if $errors;
	
	my @ekernels = $self->{'admin'}->getEntities(type => 'Kernel', hash => {});
	my @esystemimages = $self->{'admin'}->getEntities(type => 'Systemimage', hash => {});
	my @emotherboards = $self->{'admin'}->getEntities(type => 'Motherboard', hash => {});
	
	my $count = scalar @emotherboards;
	my $c =[];
	for (my $i=1; $i<=$count; $i++) {
		my $tmp->{CM}=$i;
		push(@$c, $tmp);
		$log->debug('coucou '.$id);
	}
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
	
	$tmpl->param('COUNT' => $c);
	$tmpl->param('KERNELS' => $kmodels);
	$tmpl->param('SYSTEMIMAGES' => $smodels);
	$output .= $tmpl->output();
	return $output;
}

sub process_addcluster : Runmode {
        my $self = shift;
        use CGI::Application::Plugin::ValidateRM (qw/check_rm/);
        my ($results, $err_page) = $self->check_rm('form_addcluster', '_addcluster_profile');
        return $err_page if $err_page;

        my $query = $self->query();
        eval {
                $self->{'admin'}->newOp(type =>"AddCluster", priority => '100', params => {	
			cluster_name => $query->param('name'),
			cluster_desc => $query->param('desc'),
			cluster_min_node => $query->param('min_node'),
			cluster_max_node => $query->param('max_node'),
			cluster_priority => $query->param('priority'),
			kernel_id => $query->param('kernel') ne '0' ? $query->param('kernel') : undef,
			systemimage_id => $query->param('systemimage')
                });
        };
        if($@) {
                my $error = $@;
                $self->{'admin'}->addMessage(type => 'error', content => $error);
	} else { 
		$self->{'admin'}->addMessage(type => 'success', content => 'new cluster operation adding to execution queue'); 
	}
    	$self->redirect('/cgi/mcsui.cgi/clusters/view_clusters');
}

sub _addcluster_profile {
        return {
                required => ['name', 'systemimage', 'kernel', 'min_node', 'max_node'],
                msgs => {
                                any_errors => 'some_errors',
                                prefix => 'err_'
                },
        };
}

sub form_removecluster : Runmode {
    my $self = shift;
    return 'you are on remove_cluster page';
}

1;
