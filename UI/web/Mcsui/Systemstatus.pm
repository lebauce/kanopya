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
    my @eclusters = $self->{'admin'}->getEntities(type => 'Cluster', hash => {});
    my $clusters = [];
    my $nodes = [];
    foreach my $n (@eclusters){
    	my $tmp = {};
		$tmp->{ID} = $n->getAttr(name => 'cluster_id');
		$tmp->{NAME} = $n->getAttr(name => 'cluster_name');
		#$tmp->{DESC} = $n->getAttr(name => 'cluster_desc');
		$tmp->{PRIORITY} = $n->getAttr(name => 'cluster_priority');
		#$tmp->{STATE} = $n->getAttr(name => 'cluster_state');
		#$tmp->{ACTIVE} = $n->getAttr('name' => 'active');
		my $tmpnodes = $n->getMotherboards(administrator => $self->{admin});
		$tmp->{NODESCOUNT} = scalar keys %$tmpnodes;
		
		foreach my $id (keys %$tmpnodes) {
			my $tmp2 = {};
			$tmp2->{MAC} = $tmpnodes->{$id}->getAttr(name => 'motherboard_mac_address');
			$tmp2->{NAME} = $tmp->{NAME};
			$tmp2->{IP} = $tmpnodes->{$id}->getAttr(name => 'motherboard_internal_ip');
			push @$nodes, $tmp2;
		}
		
	
		if ($n->getAttr(name => 'systemimage_id')){
			my $esystem = $self->{'admin'}->getEntity(type =>'Systemimage', id => $n->getAttr(name =>'systemimage_id'));
			$tmp->{SYSTEMIMAGE} =  $esystem->getAttr(name => 'systemimage_name');
		}else{
			$tmp->{SYSTEMIMAGE} = "";
		}
		my $ips = $n->getPublicIps();
		$tmp->{PUBLICIP} = $ips->[0]->{address};
	
		push (@$clusters, $tmp);	
    }	
    
    
    
    my $tmpl =  $self->load_tmpl('view_status.tmpl');
    $tmpl->param('TITLE_PAGE' => "System Status");
	$tmpl->param('MENU_SYSTEMSTATUS' => 1);
	$tmpl->param('CLUSTERS' => $clusters);
	$tmpl->param('NODES' => $nodes);
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
