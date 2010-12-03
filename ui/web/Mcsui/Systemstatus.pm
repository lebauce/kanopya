package Mcsui::Systemstatus;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}

# Define admin components and services we want display status. They are grouped as we want in ui.
sub adminComponentsDef {
	return [ 	[
    				{ id => 'Database', label => 'Database server', comps => [{ name => 'mysql'}] },
    				{ id => 'Boot', label => 'Boot server', comps => [{ name => 'ntpd'}, { name => 'dhcpd3'}, { name => 'atftpd'}] },
    				{ id => 'Harddisk', label => 'NAS server', comps => [{ name => 'ietd'}, { name => 'nfsd'}] }
    			],[
    				{ id => 'Monitor', label => 'Monitor', comps => [{ name => 'collector'}] },
    				{ id => 'Planner', label => 'Planner', comps => [] },
    				{ id => 'Orchestrator', label => 'Orchestrator', comps => [{ name => 'orchestrator'}] },
    			],[
    				{ id => 'Execute', label => 'Executor', comps => [{ name => 'executor'}] },
				]
  			];
}

sub xml_admin_status : Runmode {
	my $self = shift;
	     
    my $admin_components = adminComponentsDef;
    
    # Check the status of admin components and build the xml of status
	my $xml = "";
    foreach my $group (@$admin_components) {
    	foreach my $def (@$group) {
    		my ($tot, $up) = (0 ,0);
    		foreach my $serv (@{$def->{comps}}) {
    			my $grep = `ps aux | grep $serv->{name}`;
    			my $ps_count = scalar (split '\n', $grep);
    			my $status = $ps_count > 2 ? 'Up' : 'Down';
    			$up++ if ($status eq 'Up');
    			$tot++;
    			$xml .= "<elem id='status$serv->{name}' class='img$status'/>";
    		}
    		my $status = ($tot>0 && $up eq $tot) ? 'Up' : ($up>0 ? 'Broken' : 'Down');
    		$xml .= "<elem id='status$def->{id}' class='img$status'/>";
    	}
    }

	return '<data>' . $xml . '</data>';
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
    
    # Check the status of admin components and build the html template var
    my $admin_components = adminComponentsDef;
    my @components_status = ();
    foreach my $group (@$admin_components) {
    	my @res_group = ();
    	foreach my $def (@$group) {
    		my @details = ();
    		my ($tot, $up) = (0 ,0);
    		foreach my $serv (@{$def->{comps}}) {
    			my $grep = `ps aux | grep $serv->{name}`;
    			my $ps_count = scalar (split '\n', $grep);
    			my $status = $ps_count > 2 ? 'Up' : 'Down';
    			$up++ if ($status eq 'Up');
    			$tot++;
    			push @details, {name => $serv->{name}, status => $status };
    		}
    		push @res_group, {	id => $def->{id}, label => $def->{label}, details => \@details,
    							status => ($tot>0 && $up eq $tot ? 'Up' : ($up>0 ? 'Broken' : 'Down') ) };
    	}
    	push  @components_status, { group => \@res_group};
    }
    
    my $tmpl =  $self->load_tmpl('view_status.tmpl');
    $tmpl->param('TITLE_PAGE' => "System Status");
	$tmpl->param('MENU_SYSTEMSTATUS' => 1);
	$tmpl->param('CLUSTERS' => $clusters);
	$tmpl->param('NODES' => $nodes);
	$tmpl->param('COMPONENTS_STATUS' => \@components_status);
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
