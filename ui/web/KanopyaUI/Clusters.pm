package KanopyaUI::Clusters;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Cluster;
use Entity::Motherboard;
use Entity::Systemimage;
use Entity::Kernel;
use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

# clusters listing page

sub view_clusters : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Clusters/view_clusters.tmpl');
    # header / menu variables
    $tmpl->param('titlepage' => "Clusters - Clusters");
	$tmpl->param('mClusters' => 1);
	$tmpl->param('submClusters' => 1);
	$tmpl->param('username' => $self->session->param('username'));
    
    my @eclusters = Entity::Cluster->getClusters(hash => {});
    my $methods = Entity::Cluster->getPerms();
    my $clusters = [];
    	
    foreach my $n (@eclusters){
    	my $tmp = {};
    	$tmp->{link_activity} = 0;
    	
		$tmp->{cluster_id} = $n->getAttr(name => 'cluster_id');
		$tmp->{cluster_name} = $n->getAttr(name => 'cluster_name');
		my $minnode = $n->getAttr(name => 'cluster_min_node');
		my $maxnode = $n->getAttr(name => 'cluster_max_node');
		if($minnode == $maxnode) {
			$tmp->{type} = 'Static cluster';
			$tmp->{nbnodes} = "$minnode node";
			if($minnode > 1) { $tmp->{nbnodes} .= "s"; } 
		} else {
			$tmp->{type} = 'Dynamic cluster';
			$tmp->{nbnodes} = "$minnode to $maxnode nodes";
		}
		
		if($n->getAttr('name' => 'active')) {
			$tmp->{active} = 1;
			my $nbnodesup = $n->getCurrentNodesCount(); 
			if($nbnodesup > 0) {
				$tmp->{nbnodesup} = $nbnodesup;
				$tmp->{link_activity} = 1;
			} 
		} else { 
			$tmp->{active} = 0; 
		}
		$tmp->{cluster_desc} = $n->getAttr(name => 'cluster_desc');	
		push (@$clusters, $tmp);	
    }	
   
	$tmpl->param('clusters_list' => $clusters);
	  
    return $tmpl->output();
}

# cluster creation popup window

sub form_addcluster : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Clusters/form_addcluster.tmpl');
		
	my @ekernels = Entity::Kernel->getKernels(hash => {});
	my @esystemimages = Entity::Systemimage->getSystemimages(hash => {});
	my @emotherboards = Entity::Motherboard->getMotherboards(hash => {});
	
	my $count = scalar @emotherboards;
	my $c =[];
	for (my $i=1; $i<=$count; $i++) {
		my $tmp->{nodes}=$i;
		push(@$c, $tmp);
	}
	my $kmodels = [];
	foreach my $k (@ekernels) {
		my $tmp = { 
			kernel_id => $k->getAttr( name => 'kernel_id'),
			kernel_name => $k->getAttr(name => 'kernel_version')
		};
		push (@$kmodels, $tmp);	
	} 
	my $smodels = [];
	foreach my $s (@esystemimages){
		my $tmp = { 
			systemimage_id => $s->getAttr (name => 'systemimage_id'),
			systemimage_name => $s->getAttr(name => 'systemimage_name')
		};
		push (@$smodels, $tmp);
	}
	
	$tmpl->param('nodescount' => $c);
	$tmpl->param('kernels_list' => $kmodels);
	$tmpl->param('systemimages_list' => $smodels);
	$tmpl->param($errors) if $errors;
	
	return $tmpl->output();
}

# fields verification function to used with form_addcluster

sub _addcluster_profile {
	return {
    	required => ['name', 'systemimage_id', 'kernel_id', 'min_node', 'max_node', 'priority'],
        msgs => {
        	any_errors => 'some_errors',
            prefix => 'err_'
        },
	};
}

# form_addcluster processing

sub process_addcluster : Runmode {
	my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/);
    my ($results, $err_page) = $self->check_rm('form_addcluster', '_addcluster_profile');
    return $err_page if $err_page;

    my $query = $self->query();
    eval {
    	my $params = {
			cluster_name => $query->param('name'),
			cluster_desc => $query->param('desc'),
			cluster_min_node => $query->param('min_node'),
			cluster_max_node => $query->param('max_node'),
			cluster_priority => $query->param('priority'),
			systemimage_id => $query->param('systemimage_id')
		};
		if($query->param('kernel_id') ne '0') { $params->{kernel_id} = $query->param('kernel_id'); }
		my $ecluster = Entity::Cluster->new(%$params);
		$ecluster->create();
	};
    if($@) {
    	my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster creation adding to execution queue'); 
		return $self->close_window();
	}  
}

# cluster details page

sub view_clusterdetails : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Clusters/view_clusterdetails.tmpl');
	
	# header / menu variables
	$tmpl->param('titlepage' => "Cluster's overview");
	$tmpl->param('mClusters' => 1);
	$tmpl->param('submClusters' => 1);
	$tmpl->param('username' => $self->session->param('username'));

	my $query = $self->query();
	my $cluster_id = $query->param('cluster_id');
	my $ecluster = Entity::Cluster->get(id => $cluster_id);
	my $methods = $ecluster->getPerms();

	# actions visibility
	$tmpl->param('link_delete' => 0);
	$tmpl->param('link_activate' => 0);
	$tmpl->param('link_start' => 0);
	$tmpl->param('link_addnode' => 0);
	if($methods->{'setperm'}->{'granted'}) { $tmpl->param('can_setperm' => 1); }
	
	$tmpl->param('cluster_id' => $cluster_id);
	$tmpl->param('cluster_name' => $ecluster->getAttr(name => 'cluster_name'));
	$tmpl->param('cluster_desc' => $ecluster->getAttr(name => 'cluster_desc'));
	$tmpl->param('cluster_priority' => $ecluster->getAttr(name => 'cluster_priority'));
	
	my $minnode = $ecluster->getAttr(name => 'cluster_min_node');
	my $maxnode = $ecluster->getAttr(name => 'cluster_max_node');
	$tmpl->param('cluster_min_node' => $minnode);
	$tmpl->param('cluster_max_node' => $maxnode);
	if($minnode == $maxnode) {
		$tmpl->param('type' => 'Static cluster');
	} else {
		$tmpl->param('type' => 'Dynamic cluster');
	}
	
	my $systemimage_id = $ecluster->getAttr(name => 'systemimage_id');
	if($systemimage_id) {
		my $esystemimage = Entity::Systemimage->get(id => $systemimage_id);
		$tmpl->param('systemimage_name' =>  $esystemimage->getAttr(name => 'systemimage_name'));
		$tmpl->param('systemimage_active' => $esystemimage->getAttr('name' => 'active'));		 
	}
	
	my $kernel_id = $ecluster->getAttr(name =>'kernel_id');
	if($kernel_id) {
		my $ekernel = Entity::Kernel->get(id => $kernel_id);
		$tmpl->param('kernel' => $ekernel->getAttr(name => 'kernel_version'));
	} else {
		$tmpl->param('kernel' => 'no specific kernel');
	}
	
	my $publicips = $ecluster->getPublicIps();
	$tmpl->param('publicip_list' => $publicips);
	$tmpl->param('nbpublicips' => scalar(@$publicips)+1);
	
	# state info
	my $motherboards = $ecluster->getMotherboards(administrator => $self->{adm});
	my $nbnodesup = scalar(keys(%$motherboards)); 
	my $nodes = [];
	
	my $active = $ecluster->getAttr('name' => 'active');
	if($active) {
		$tmpl->param('active' => 1);
		$tmpl->param('link_activate' => 0);
		
		if($nbnodesup > 0) {
			$tmpl->param('nbnodesup' => $nbnodesup+1);	
			if($minnode != $maxnode and $nbnodesup < $maxnode) { 
				$tmpl->param('link_addnode' => 1);
			}
		} else {
			$tmpl->param('link_start' => 1);	
		}
		
	} else { 
		$tmpl->param('active' => 0);
		$tmpl->param('link_activate' => 1);
		$tmpl->param('link_delete' => 1);
	}
	
	# components list
	my $components = $ecluster->getComponents(category => 'all');
	my $comps = [];
			
	while( my ($instance_id, $comp) = each %$components) {
		my $comphash = {};
		my $compAtt = $comp->getComponentAttr();
		$comphash->{component_instance_id} = $instance_id;
		$comphash->{component_name} = $compAtt->{component_name};
		$comphash->{component_version} = $compAtt->{component_version};
		$comphash->{component_category} = $compAtt->{component_category};
		$comphash->{cluster_id} = $cluster_id;
		$comphash->{link_remove} = not $active;
				
		push (@$comps, $comphash);
	}
	$tmpl->param('nbcomponents' => scalar(@$comps)+1);
	$tmpl->param('components_list' => $comps);
	
	# nodes list
	if($nbnodesup) {
		my $id = $ecluster->getMasterNodeId();
		my $masternode = $motherboards->{ $id };
		my $tmp = {
			motherboard_id => $masternode->getAttr(name => 'motherboard_id'),
			motherboard_hostname => $masternode->getAttr(name => 'motherboard_hostname'),
			motherboard_internal_ip => $masternode->getAttr(name => 'motherboard_internal_ip'),
			link_remove => 0
		};
		delete $motherboards->{ $id };
		push @$nodes, $tmp;
		
		while( my ($id, $n) = each %$motherboards) {
			$tmp = {};
			$tmp->{motherboard_id} = $id;
			$tmp->{cluster_id} = $cluster_id;
			$tmp->{motherboard_hostname} = $n->getAttr(name => 'motherboard_hostname'); 	
			$tmp->{motherboard_internal_ip} = $n->getAttr(name => 'motherboard_internal_ip');
			$tmp->{link_remove} = 1;
			push @$nodes, $tmp;
		}
	}
	
	$tmpl->param('nodes_list' => $nodes);
	return $tmpl->output();
}

# TODO cluster edition popup window

sub form_editcluster : Runmode {
	return "TODO";
}

# cluster deletion processing

sub process_removecluster : Runmode {
    my $self = shift;
    my $query = $self->query();
	eval {
		my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
		$ecluster->remove();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster removing adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/clusters/view_clusters');
	} 
}

# component addition popup window

sub form_addcomponenttocluster : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $cluster_id = $query->param('cluster_id');
	my ($ecluster, $esystemimage, $systemimage_components, $cluster_components);
	eval {
		$ecluster = Entity::Cluster->get(id => $cluster_id);
		$esystemimage = Entity::Systemimage->get(id => $ecluster->getAttr(name => 'systemimage_id'));
		$systemimage_components = $esystemimage->getInstalledComponents();
		$cluster_components = $ecluster->getComponents(administrator => $self->{adm}, category => 'all');
	};
	if($@) {
    	my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		my $components = []; 
		foreach my $c  (@$systemimage_components) {	
			my $found = 0;
			while(my ($instance_id, $component) = each %$cluster_components) {
				my $attrs = $component->getComponentAttr();
				if($attrs->{component_id} eq $c->{component_id}) { $found = 1; }
			}
			if(not $found) { push @$components, $c; };
		} 
		my $tmpl = $self->load_tmpl('Clusters/form_addcomponenttocluster.tmpl');
		$tmpl->param('cluster_id' => $cluster_id);
		$tmpl->param('cluster_name' => $ecluster->getAttr(name => 'cluster_name'));
		$tmpl->param('components_list' => $components);
	
		return $tmpl->output();
	}
}

#  form_addcomponenttocluster processing

sub process_addcomponent : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
	    my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
	    $ecluster->addComponent(component_id => $query->param('component_id'));
	};
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
    }	
	else { 
		$self->{adm}->addMessage(from => 'Administrator',level => 'info', content => 'Component added sucessfully'); 
		return $self->close_window();	
	}
}

# cluster component removing processing

sub process_removecomponent : Runmode {
	my $self = shift;
	my $query = $self->query();
	eval {
	    my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
	    $ecluster->removeComponent(component_instance_id => $query->param('component_instance_id'));
	};
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	} 
	else { 
		$self->{adm}->addMessage(from => 'Administrator',level => 'info', content => 'Component removed sucessfully'); 
   		$self->redirect("/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id=".$query->param('cluster_id'));
	}
}

# cluster activation processing

sub process_activatecluster : Runmode {
    my $self = shift;
	my $query = $self->query();
	eval {
		my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
		$ecluster->activate();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
		}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster activation adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id'));
	} 
}    

# cluster deactivation processing

sub process_deactivatecluster : Runmode {
    my $self = shift;
    my $query = $self->query();
	eval {
		my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
		$ecluster->deactivate();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
		}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster activation adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id'));
	}
}

# cluster public ip popup window

sub form_setpubliciptocluster : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Clusters/form_setpubliciptocluster.tmpl');
	my $output = '';
	my $query = $self->query();	
	my $freepublicips = $self->{adm}->{manager}->{network}->getFreePublicIPs();
	
	$tmpl->param('CLUSTER_ID' => $query->param('cluster_id'));
	$tmpl->param('FREEPUBLICIPS' => $freepublicips);
	
	$output .= $tmpl->output();
	return $output;
}

# form_setpubliciptocluster processing

sub process_setpubliciptocluster : Runmode {
	my $self = shift;
    my $query = $self->query();
    eval {
    	$self->{adm}->{manager}->{network}->setClusterPublicIP(
    		publicip_id => $query->param('publicip_id'),
    		cluster_id => $query->param('cluster_id'),
    	);
    };
    if($@) { 
		my $error = $@;
		$self->{adm}->addMessage(from => 'Administrator',level => 'error', content => $error); 
	} else { $self->{adm}->addMessage(from => 'Administrator',level => 'info', content => 'new public ip added to cluster.'); }
    return $self->close_window();
}

# cluster start processing

sub process_startcluster : Runmode {
	my $self = shift;
	my $query = $self->query();
    eval {
	    my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id')); 
		$ecluster->start();
    };
    if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
		}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster start adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id'));
	} 
}

# cluster stop processing

sub process_stopcluster : Runmode {
	my $self = shift;
	my $query = $self->query();
    eval {
	    my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id')); 
		$ecluster->stop();
    };
    if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
		}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster stop adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id'));
	} 
}

# cluster node removing processing

sub process_removenode : Runmode {
	my $self = shift;
	my $query = $self->query();
    eval {
    	my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
	    $ecluster->removeNode(motherboard_id => $query->param('motherboard_id'));
    };
   	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'cluster remove node adding to execution queue'); 
		$self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id'));
	} 
}

# cluster node addition processing

sub process_addnode : Runmode {
	my $self = shift;
	my $query = $self->query();
	        
    eval {
	    my $ecluster = Entity::Cluster->get(id => $query->param('cluster_id'));
	    my @free_motherboards = Entity::Motherboard->getMotherboards(hash => { active => 1, motherboard_state => 'down'});
	    if(not scalar @free_motherboards) {
	    	my $errmsg = 'no motherboard is available ; can\'t add a new node to this cluster';
	    	$self->{adm}->addMessage(from => 'Administrator',level => 'error', content => $errmsg); 
	    }
	    else {
	        my $motherboard = pop @free_motherboards;
	     	$ecluster->addNode(motherboard_id => $motherboard->getAttr(name => 'motherboard_id')); 
	    	$self->{adm}->addMessage(from => 'Administrator',level => 'info', content => 'AddMotherboardInCluster operation adding to execution queue');
	    }
    };
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	} 
	else { 
    	$self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id'));
	}
}



1;
