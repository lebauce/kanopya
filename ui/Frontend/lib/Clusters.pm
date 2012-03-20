package Clusters;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Administrator;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Host;
use Entity::Gp;
use Entity::Systemimage;
use Entity::Kernel;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("webui");

prefix '/architectures';

sub _timestamp_format {
    my %args = @_;
    
    return 'unk' if (not defined $args{timestamp});
    
    my $period = time() - $args{timestamp};
   	my @time = (int($period/3600), int(($period % 3600) / 60), $period % 60);
    my $time_str = "";
    $time_str .= $time[0] . "h" if ($time[0] > 0);
    $time_str .= $time[1] . "m" if ($time[0] > 0 || $time[1] > 0);
    $time_str .= $time[2] . "s"; 
    
    return $time_str;
}

sub _clusters {

    my @eclusters = Entity::ServiceProvider::Inside::Cluster->getClusters(hash => {});
    my $clusters = [];
    my $clusters_list;
    my $can_create;
    my $can_configure;
    foreach my $n (@eclusters){
        my $tmp = {
            route_base           => 'clusters',
            link_activity        => 0,
            cluster_id           => $n->getAttr(name => 'cluster_id'),
            cluster_name         => $n->getAttr(name => 'cluster_name'),
            cluster_basehostname => $n->getAttr(name=>'cluster_basehostname')
            
        };
        my  $user_id = $n->getAttr(name=>'user_id');
        my $minnode = $n->getAttr(name => 'cluster_min_node');
        my $maxnode = $n->getAttr(name => 'cluster_max_node');
        if ( $minnode == $maxnode ) {
            $tmp->{type}    = 'Static cluster';
            $tmp->{nbnodes} = "$minnode node";
            $tmp->{nbnodes} .= "s" if ( $minnode > 1 );
        } else {
            $tmp->{type} = 'Dynamic cluster';
            $tmp->{nbnodes} = "$minnode to $maxnode nodes";
        }

        if ( $n->getAttr('name' => 'active') ) {
            $tmp->{active} = 1;
            my $nbnodesup = $n->getCurrentNodesCount();
            if($nbnodesup > 0) {
                $tmp->{nbnodesup}     = $nbnodesup;
                $tmp->{link_activity} = 1;
            }

             my $cluster_state = $n->getAttr('name' => 'cluster_state');
            for my $state ('up', 'starting', 'stopping', 'down', 'broken') {
                $tmp->{"state_$state"} = 1 if ( $cluster_state =~ $state );
            }
        } else {
            $tmp->{active} = 0;
        }
        $tmp->{cluster_desc} = $n->getAttr(name => 'cluster_desc');
        push (@$clusters, $tmp);
    }

    #$clusters_list = $clusters;
    #if($methods->{'create'}->{'granted'}) {
        #my @si = Entity::Systemimage->getSystemimages(hash => {});
        #if (scalar @si){
            #$can_create = 1
        #}
    #}

    return $clusters;
}

sub _externalclusters {
    my @extclusters = Entity::ServiceProvider::Outside::Externalcluster->search(hash => {});
    
    my @clusters;
    foreach my $cluster (@extclusters) {
        
        my $nodes = $cluster->getNodes();
        my $nbnodes = scalar(@$nodes);
        
        push @clusters, {
            route_base      => 'extclusters',
            link_activity   => 1,
            type            => 'External cluster',
            active          => 1,
            state_up        => 1,
            cluster_id      => $cluster->getAttr(name => 'externalcluster_id'),
            cluster_name    => $cluster->getAttr(name => 'externalcluster_name'),
            cluster_desc    => $cluster->getAttr(name => 'externalcluster_desc'),
            nbnodes         => $nbnodes,
            nbnodesup       => $nbnodes,
        };
    }
    
    return \@clusters;
}

# return an array containing running clusters with Cloudmanager component

sub _virtualization_clusters {
	my @clusters = Entity::ServiceProvider::Inside::Cluster->getClusters(hash => {});
	my @virtualization_clusters = ();
	foreach my $cluster (@clusters) {
		my $components = $cluster->getComponents(category => 'Cloudmanager');
		my ($state, $timestamp) = $cluster->getState();
		if(scalar(keys %$components) && $state eq 'up') {
			push @virtualization_clusters, $cluster;
		}
	}
	return @virtualization_clusters;
}
#return user groups
sub _groups {
	  my $selected = shift;
    my @egroups = Entity::Gp->getGroups(hash => { gp_type => "User" });
    my $groups  = [];
    if($selected) {
        if(!scalar(grep(/$selected/, @egroups))) {
            redirect('/architectures/clusters');
        }
    }


    foreach my $group (@egroups) {
        my $tmp = {};
        $tmp->{gp_id}   = $group->getAttr('name' => 'gp_id');
        $tmp->{gp_name} = $group->getAttr('name' => 'gp_name');
        $tmp->{gp_desc} = $group->getAttr('name' => 'gp_desc');
        $tmp->{gp_type} = $group->getAttr('name' => 'gp_type');
        $tmp->{gp_size} = $group->getSize();
        $tmp->{selected} = 'selected' if $selected eq $group;

        push(@$groups, $tmp);
    }

    return $groups;
}

get '/clusters/userid/:userid' => sub {
 my $user_id = param('userid');
 return Dumper($user_id);
};

get '/clusters/users/:gpid' => sub {
	 my $adm = Administrator->new();
	 my $loguser=$adm->{_rightchecker}->{user_id};
	 my $loguser_entity=Entity::User->get(id=>$loguser);
	 
     my $gp_id = param('gpid');
     my $gp_selected=Entity::Gp->get(id=>param('gpid'));
     my @eusers= $gp_selected->getEntities();
     my $str="<option value="."$loguser".">"."current"." "."</option>";
     foreach my $u (@eusers) {
	   my $tmp = {};
	   $tmp->{user_firstname} = $u->getAttr(name=>'user_firstname');
	   $tmp->{user_lastname}=$u->getAttr(name=>'user_lastname');
	   $tmp->{user_id}=$u->getAttr(name=>'user_id');
	   $str .="<option value="."$tmp->{user_id}".">"."$tmp->{user_firstname} "."$tmp->{user_lastname}"."</option>";
	  
   }
    content_type('text/html');
  return $str;
 };

sub _users_list { return (); }
get '/clusters/add' => sub {
    my $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(hash=>{cluster_name => 'Kanopya'});
    my @ekernels = Entity::Kernel->getKernels(hash => {});
    my @esystemimages_forshared = Entity::Systemimage->getSystemimages(hash => {systemimage_dedicated => {'!=',1}});
    my @esystemimages_fordedicated = Entity::Systemimage->getSystemimages(hash => {active => 0});
    my @ehosts = Entity::Host->getHosts(hash => {});
    my $count = scalar @ehosts;
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
    my $si_forshared = [];
    foreach my $s (@esystemimages_forshared){
        my $tmp = {
            systemimage_id => $s->getAttr(name => 'systemimage_id'),
            systemimage_name => $s->getAttr(name => 'systemimage_name')
        };
        push (@$si_forshared, $tmp);
    }
    my $si_fordedicated = [];
    foreach my $s (@esystemimages_fordedicated){
        my $tmp = {
            systemimage_id => $s->getAttr(name => 'systemimage_id'),
            systemimage_name => $s->getAttr(name => 'systemimage_name')
        };
        push (@$si_fordedicated, $tmp);
    }

    template 'form_addcluster', {
        title_page                  => "Clusters - Cluster creation",
        'nodescount'                => $c,
        'kernels_list'              => $kmodels,
        'systemimages_forshared'    => $si_forshared,
        'systemimages_fordedicated' => $si_fordedicated,
        'gp_list'                   => _groups(),
        'users_list'                => _users_list(),
        'nameserver'                => $kanopya_cluster->getAttr(name => 'cluster_nameserver'),
    }, { layout => '' };
};

post '/clusters/add' => sub {
    my $adm = Administrator->new;
    
    my ($si_location, $si_access_mode, $si_shared, $systemimage_id);

    $si_location = params->{'si_location'};
    if($si_location eq 'local') {
        $si_access_mode = 'rw';
        $si_shared = 0;
    } elsif($si_location eq 'diskless') {
        if(params->{'si_shareordedicate'} eq 'shared') {
            $si_access_mode = 'ro';
            $si_shared = 1;
            $systemimage_id = params->{'systemimage_forshared'};
        } else {
            $si_access_mode = 'rw';
            $si_shared = 0;
            $systemimage_id = params->{'systemimage_fordedicated'};
        }
    }

    eval {
        my $params = {
            cluster_name           => params->{'name'},
            cluster_desc           => params->{'desc'},
            cluster_si_location    => $si_location,
            cluster_si_access_mode => $si_access_mode,
            cluster_si_shared      => $si_shared,
            cluster_min_node       => params->{'min_node'},
            cluster_max_node       => params->{'max_node'},
            cluster_priority       => params->{'priority'},
            systemimage_id         => $systemimage_id,
            cluster_domainname     => params->{'domainname'},
            cluster_nameserver     => params->{'nameserver'},
            cluster_basehostname   => params->{'cluster_basehostname'},
            user_id                => params->{'user_id'}
        };
        if(params->{'kernel_id'} ne '0') { $params->{kernel_id} = params->{'kernel_id'}; }
        Entity::ServiceProvider::Inside::Cluster->create(%$params);
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else {
        $exception->rethrow();
     #   return $self->error_occured("Error during operation enqueuing : $exception->error");
        }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster creation adding to execution queue');
        redirect '/architectures/clusters';
    }
};

get '/extclusters/add' => sub {
    
    template 'form_addexternalcluster', {
        title_page                  => "External Clusters - Add",
    }, { layout => '' };
};

post '/extclusters/add' => sub {
    my $adm = Administrator->new;
    
    my $params = {
        externalcluster_name           => params->{'name'},
        externalcluster_desc           => params->{'desc'},
    };
    my $new_cluster_id;
    eval {
        my $new_extcluster = Entity::ServiceProvider::Outside::Externalcluster->new(%$params);
        $new_cluster_id = $new_extcluster->getAttr(name => 'externalcluster_id');
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'external cluster created. Inserting initial data...');
        $new_extcluster->monitoringDefaultInit();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else {
            $exception->rethrow();
        }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'external cluster created (id:'.$new_cluster_id.')');
        redirect "/architectures/extclusters/$new_cluster_id";
    }
};


get '/clusters' => sub {
    my $can_create;

    my $methods = Entity::ServiceProvider::Inside::Cluster->getPerms();
    if($methods->{'create'}->{'granted'}) {
        my @si = Entity::Systemimage->getSystemimages(hash => {});
        if (scalar @si){
            $can_create = 1;
        }
    }
    
    template 'clusters', {
        title_page         => 'Clusters - Clusters',
        clusters_list => [ @{_clusters()}, @{_externalclusters()} ],
        can_create => $can_create,
        
    }, { layout => 'main' };
};

get '/extclusters' => sub {
    my $can_create;

    template 'clusters', {
        title_page         => 'Clusters - External Clusters',
        clusters_list => _externalclusters(),
    }, { layout => 'main' };
};

get '/clusters/:clusterid' => sub {
    my $cluster_id = params->{clusterid};
    my $can_configure;
    my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
    my $methods = $ecluster->getPerms();
    my $minnode = $ecluster->getAttr(name => 'cluster_min_node');
    my $maxnode = $ecluster->getAttr(name => 'cluster_max_node');
    my $cluster_basehostname = $ecluster->getAttr(name=>'cluster_basehostname');
    my $systemimage_id = $ecluster->getAttr(name => 'systemimage_id');
    my $user_id = $ecluster->getAttr(name => 'user_id');
    my ($systemimage_name, $systemimage_active);
    if($systemimage_id) {
        my $esystemimage = eval { Entity::Systemimage->get(id => $systemimage_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $systemimage_name = '-';
            $systemimage_active = '-';
        } else {
            $systemimage_name =  $esystemimage->getAttr(name => 'systemimage_name');
            $systemimage_active = $esystemimage->getAttr('name' => 'active');
        }
    }

    my $kernel_id = $ecluster->getAttr(name =>'kernel_id');
    my $kernel;
    if($kernel_id) {
        my $ekernel = eval { Entity::Kernel->get(id => $kernel_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $kernel = '-';
        } else {
            $kernel = $ekernel->getAttr(name => 'kernel_version');
        }
    } else {
        $kernel = 'no specific kernel';
    }

    my $publicips = $ecluster->getPublicIps();
    
    # state info
    my ($cluster_state, $timestamp) = split ':', $ecluster->getAttr('name' => 'cluster_state');
    if($cluster_id==1) {$can_configure=1}
    else
    {
		if($cluster_state ne "down")
           {$can_configure=0;}
           else{$can_configure=1}
	}
	 
    my $hosts = $ecluster->getHosts(administrator => Administrator->new);
    my $nbnodesup = scalar(keys(%$hosts));
    my $nodes = [];

    my $active = $ecluster->getAttr('name' => 'active');
    my $link_activate = 0;
    my $link_addnode = 0;
    my $link_start = 0;
    my $link_deactivate = 0;
    my $link_delete = 0;

    if($active) {
        $link_activate = 0;
        if($nbnodesup > 0) {
            if($minnode != $maxnode and $nbnodesup < $maxnode) {
                $link_addnode = 1;
            }
        } else {
            $link_start = 1;
            $link_deactivate = 1;
        }
    } else {
        $link_activate = 1;
        $link_delete = 1;
    }
    # components list
    my $components = $ecluster->getComponents(category => 'all');
    my $comps = [];

    while( my ($component_id, $comp) = each %$components) {
        my $comphash = {};
        my $compAtt = $comp->getComponentAttr();
        $comphash->{component_id} = $component_id;
        $comphash->{component_name} = $compAtt->{component_name};
        $comphash->{component_version} = $compAtt->{component_version};
        $comphash->{component_category} = $compAtt->{component_category};
        $comphash->{cluster_id} = $cluster_id;
        if(not $methods->{'configureComponents'}->{'granted'} ) {
                $comphash->{'link_configurecomponents'} = 0;
        } else { $comphash->{'link_configurecomponents'} = 1;}
        if(not $methods->{'removeComponent'}->{'granted'} ) {
                $comphash->{link_remove} = 0;
        } else { $comphash->{link_remove} = not $active;}


        push (@$comps, $comphash);
    }

    # nodes list
    if($nbnodesup) {
        my $master_id = $ecluster->getMasterNodeId();
        while( my ($id, $n) = each %$hosts) {
            my $tmp = {
                host_id => $id,
                host_hostname => $n->getAttr(name => 'host_hostname'),
                host_internal_ip => $n->getInternalIP()->{ipv4_internal_address},
                cluster_id => $cluster_id,
            };
            
            # Manage remove link
            if ($id == $master_id) {
                $tmp->{link_remove} = 0;
                $tmp->{master_node} = 1;
            } else {
                if(not $methods->{'removeNode'}->{'granted'} ) {
                    $tmp->{link_remove} = 0;
                } else { $tmp->{link_remove} = 1;}
            }

            # Manage node state
            my ($node_state, $time_stamp) = $n->getNodeState();
            # The first elem is the regexp to match with the state and the second elem is the associated state for ui 
            for my $state ( ['^in', 'up'],                # node 'in' is displayed as 'Up'
                            ['goingin', 'starting'],    # match pregoingin, goingin and diplayed as starting
                            ['goingout', 'stopping'],    # match pregoingout, goingout and diplayed as stopping
                            ['broken','broken']) {        # broken
                if ( $node_state =~ $state->[0] ) {
                    $tmp->{"state_$state->[1]"} = 1;
                }
            }
            $tmp->{"real_state"} = $node_state;
            $tmp->{"state_time"} = _timestamp_format( timestamp => $time_stamp );

            push @$nodes, $tmp;
        }
    }

    my $link_stop = ! $link_start;

    template 'clusters_details', {
        title_page         => "Clusters - Cluster's overview",
        cluster_id         => $cluster_id,
        can_configure      =>$can_configure,
        cluster_name       => $ecluster->getAttr(name => 'cluster_name'),
        cluster_desc       => $ecluster->getAttr(name => 'cluster_desc'),
        cluster_priority   => $ecluster->getAttr(name => 'cluster_priority'),
        cluster_domainname => $ecluster->getAttr(name => 'cluster_domainname'),
        cluster_nameserver => $ecluster->getAttr(name => 'cluster_nameserver'),
        cluster_min_node   => $minnode,
        cluster_max_node   => $maxnode,
        cluster_basehostname => $cluster_basehostname,
        user_id             => $user_id,
        type               => $minnode == $maxnode ? 'Static cluster' : 'Dynamic cluster',
        systemimage_name   => $systemimage_name,
        systemimage_active => $systemimage_active,
        systemimage_id     => $systemimage_id,
        kernel             => $kernel,
        publicip_list      => $publicips,
        nbpublicips        => scalar(@$publicips),
        active             => $active,
        cluster_state      => $cluster_state,
        state_time         => _timestamp_format( timestamp => $timestamp ),
        nbnodesup          => $nbnodesup,
        nbcomponents       => scalar(@$comps),
        components_list    => $comps,
        nodes_list         => $nodes,
        link_delete        => $methods->{'remove'}->{'granted'} ? $link_delete : 0,
        link_activate      => $methods->{'activate'}->{'granted'} ? $link_activate : 0,
        link_deactivate    => $methods->{'deactivate'}->{'granted'} ? $link_deactivate : 0,
        link_start         => $methods->{'start'}->{'granted'} && $link_start,
        link_stop          => $methods->{'stop'}->{'granted'} && $link_stop,
        link_edit          => $methods->{'update'}->{'granted'}, 
        link_addnode       => $methods->{'addNode'}->{'granted'} ? $link_addnode : 0,
        link_addcomponent  => $methods->{'addComponent'}->{'granted'} && ! $active,
        can_setperm        => $methods->{'setperm'}->{'granted'},        
                       
     }, { layout => 'main' };
};

get '/extclusters/:clusterid' => sub {
    my $cluster_id = params->{clusterid};
    
    my $extcluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => $cluster_id);
    
    # Nodes list
    my $num_noderule_verif    = 0;
    
    my $nodes = $extcluster->getNodes(shortname => 1);
    
    my $num_node_nok = 0; 
    foreach my $node (@$nodes) {
        $node->{"state_" . $node->{state}} = 1;
        $num_noderule_verif += $node->{num_verified_rules};
        
        if($node->{num_verified_rules} > 0){
            $num_node_nok++;
        }
    }
    
    # Connectors
    my @connectors = map { 
        {
            'connector_id'              => $_->getAttr(name => 'connector_id'),
            'link_configureconnector'   => 1,
            'link_remove'               => 1,
            %{$_->getConnectorType()},
        }
    } $extcluster->getConnectors();


     
    my $num_node_rule_total = scalar NodemetricRule->searchLight(
                                    hash=>{
                                        'nodemetric_rule_service_provider_id' => $cluster_id,
                                        'nodemetric_rule_state' => 'enabled',
                                    }
                                 );


    
    my $num_clusterrule_verif   = 0;
    my @enabled_aggregaterules = AggregateRule->getRules(state => 'enabled', service_provider_id=>$cluster_id);

    my $num_cluster_rule_total = scalar @enabled_aggregaterules;
    
    foreach my $rule (@enabled_aggregaterules){        
        my $last_eval = $rule->getAttr(name => 'aggregate_rule_last_eval');
        if( defined $last_eval and $last_eval == 1){
            $num_clusterrule_verif++;
        } 
    }

    my @nodes_sort = sort {$b->{num_verified_rules} cmp $a->{num_verified_rules}} @{$nodes}; 
    
    template 'extclusters_details', {
        title_page            => "External Clusters - Cluster's overview",
        active                => 1,
        cluster_state         => $extcluster->getAttr(name => 'externalcluster_state'),
        cluster_id            => $cluster_id,
        cluster_name          => $extcluster->getAttr(name => 'externalcluster_name'),
        nodes_list            => \@nodes_sort,#$nodes,
        connectors_list       => \@connectors,
        link_updatenodes      => 1,
        link_addconnector     => 1,
        link_delete           => 1,
        can_configure         => 1,
        num_node_rule_total   => $num_node_rule_total,
        num_cluster_rule_total => $num_cluster_rule_total,
        num_noderule_verif    => $num_noderule_verif,
        num_clusterrule_verif => $num_clusterrule_verif,
        num_node_nok          => $num_node_nok,
    }, { layout => 'main' };
};

get '/extclusters/:clusterid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('clusterid'));
        $cluster->delete();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster ' . param('clusterid') . ' removed.');
        redirect('/architectures/clusters');
    }
};

get '/clusters/:clusterid/activate' => sub {
    my $adm = Administrator->new;
    my $ecluster;
    eval {
        $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->activate();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            forward('/permission_denied');
        }
        else { $exception->rethrow(); }
        }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster activation adding to execution queue');
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};

get '/clusters/:clusterid/deactivate' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->deactivate();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
        }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster deactivation adding to execution queue');
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};

get '/clusters/:clusterid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->remove();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster removing adding to execution queue');
        redirect('/architectures/clusters');
    }
};

get '/clusters/:clusterid/start' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->start();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
        }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster start adding to execution queue');
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};

get '/clusters/:clusterid/stop' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->stop();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
        }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster stop adding to execution queue');
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};

get '/clusters/:clusterid/forcestop' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->forceStop();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
        }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster force stop adding to execution queue');
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};

get '/clusters/:clusterid/components/add' => sub {
    my $adm = Administrator->new;
    my $cluster_id = param('clusterid');
    my ($ecluster, $esystemimage, $systemimage_components, $cluster_components);
    my $components = [];
    eval {
        $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
        $esystemimage = Entity::Systemimage->get(id => $ecluster->getAttr(name => 'systemimage_id'));
        $systemimage_components = $esystemimage->getInstalledComponents();
        
        $cluster_components = $ecluster->getComponents(administrator => $adm, category => 'all');
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        foreach my $c  (@$systemimage_components) {
            my $found = 0;
            
            while(my ($component_id, $component) = each %$cluster_components) {
                my $attrs = $component->getComponentAttr();
                if($attrs->{component_type_id} eq $c->{component_type_id}) { $found = 1; }
            }
            if(not $found) { push @$components, $c; };
        }
    }

    template 'form_addcomponenttocluster', {
        cluster_id         => $cluster_id,
        cluster_name       => $ecluster->getAttr(name => 'cluster_name'),
        components_list    => $components
    }, { layout => '' };
};

post '/clusters/:clusterid/components/add' => sub {
    my $adm = Administrator->new;
    my $component_id;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $component_id = $ecluster->addComponentFromType(component_type_id => param('component_type_id'));
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'Component added sucessfully');
        redirect("/systems/components/$component_id/configure");
    }
};

get '/clusters/:clusterid/components/:instanceid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->removeComponent(component_instance_id => param('instanceid'));
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'Component removed sucessfully');
        redirect("/architectures/clusters/".param('clusterid'));
    }
};

get '/extclusters/:clusterid/connectors/add' => sub {
    my $adm = Administrator->new;
    my $cluster_id = param('clusterid');

    my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('clusterid'));

    my $connectors = Entity::Connector->getConnectorTypes();

    template 'form_addconnectortocluster', {
        cluster_id         => $cluster_id,
        cluster_name       => $cluster->getAttr(name => 'externalcluster_name'),
        connectors_list    => $connectors
    }, { layout => '' };
};

post '/extclusters/:clusterid/connectors/add' => sub {
    my $adm = Administrator->new;
    my $connector_id;
    eval {
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('clusterid'));
        $connector_id = $cluster->addConnectorFromType(connector_type_id => param('connector_type_id'));
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'Connector added sucessfully');
        redirect("/systems/connectors/$connector_id/configure");
    }
};

get '/extclusters/:clusterid/connectors/:instanceid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('clusterid'));
        $cluster->removeConnector(connector_id => param('instanceid'));
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'Connector removed sucessfully');
        redirect("/architectures/extclusters/".param('clusterid'));
    }
};

get '/clusters/:clusterid/ips/public/add' => sub {
    my $adm = Administrator->new;
    my $freepublicips = $adm->{manager}->{network}->getFreePublicIPs();

    template 'form_setpubliciptocluster', {
        cluster_id         => param('clusterid'),
        freepublicips_list => $freepublicips
    }, { layout => '' };
};

post '/clusters/:clusterid/ips/public/add' => sub {
    my $adm = Administrator->new;
    eval {
        $adm->{manager}->{network}->setClusterPublicIP(
            publicip_id => param('publicip_id'),
            cluster_id => param('clusterid'),
        );
    };
    if($@) {
        my $error = $@;
        $adm->addMessage(from => 'Administrator',level => 'error', content => $error);
    } else {
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'new public ip added to cluster.');
    }
    redirect('/architectures/clusters/'.param('clusterid'));
};

get '/clusters/:clusterid/ips/public/:ipid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        $adm->{manager}->{network}->unsetClusterPublicIP(
            publicip_id => param('ipid'),
            cluster_id => param('clusterid'),
        );
    };
    if($@) {
        my $error = $@;
        $adm->addMessage(from => 'Administrator',level => 'error', content => $error);
    } else {
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'public ip removed from cluster.');
    }
    redirect('/architectures/clusters/'.param('clusterid'));
};

get '/clusters/:clusterid/nodes/add' => sub {
	
	my @freehosts = Entity::Host->getFreeHosts();
	#$log->info("nombre de free hosts : ".scalar(@freehosts));
	my $physical_hosts = [];
	foreach my $host (@freehosts) {
		my $tmp = {
			host_id 	=> $host->getAttr(name => 'host_id'),
			host_label  => $host->toString(),
		};
		push @$physical_hosts, $tmp;
	}
	
	my @virtclusters = _virtualization_clusters();
    $log->info("nombre de virt clusters : ".scalar(@virtclusters));
    my $virt_clusters = [];
    foreach my $cluster (@virtclusters) {
		my $tmp = {
			cluster_id 	  => $cluster->getAttr(name => 'cluster_id'),
			cluster_name  => $cluster->getAttr(name => 'cluster_name'),
		};
		push @$virt_clusters, $tmp;
	}
    
    template 'form_addnode', {
        title_page                  => "Clusters - Add node",
        'cluster_id'                => params->{clusterid},
        'physical_hosts'			=> $physical_hosts,
        'virt_clusters'			    => $virt_clusters,
        'vm_template'				=> [],
        

    }, { layout => '' };
    

};

post '/clusters/:clusterid/nodes/add' => sub {
    my $adm = Administrator->new;
    
    my %args = (
		type          => param('node_type') eq 'auto' ? undef : param('node_type'),
		core          => param('core')    eq '' ? undef : param('core'),
		ram			  => param('ram')     eq '' ? undef : param('ram'),
		host_id       => param('host_id') eq '-1' ? undef : param('host_id'),
		cloud_cluster => param('cloud_cluster') eq '-1' ? undef : param('cloud_cluster'),
    );
    
    
    
    eval {
        my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $cluster->addNode(%args);
        $adm->addMessage(from => 'Administrator',level => 'info', content => 'AddHostInCluster operation adding to execution queue');
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};

get '/clusters/:clusterid/nodes/:nodeid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => param('clusterid'));
        $ecluster->removeNode(host_id => param('nodeid'));
    };
       if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect('/permission_denied');
        }
        else { $exception->rethrow(); }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster remove node adding to execution queue');
        redirect('/architectures/clusters/'.param('clusterid'));
    }
};


get '/extclusters/:clusterid/nodes/update' => sub {
    my $adm = Administrator->new;
    my %res;
    my $node_count;

    eval {
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('clusterid'));
        $node_count = $cluster->updateNodes( password => param('password') );
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            $res{redirect} = '/permission_denied';
        }
        else { $res{msg} = "$exception"; }
    }
    else {
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'cluster successfully update nodes');
        $res{msg} = "$node_count node" . ( $node_count > 1 ? 's' : '') . " retrieved.";
    }
    
    to_json \%res;
};

1;
