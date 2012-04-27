package Clusters;

use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Administrator;
use General;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::ServiceProvider;
use Entity::HostManager;
use Entity::Host;
use Entity::Gp;
use Entity::Masterimage;
use Entity::Kernel;
use Entity::InterfaceRole;
use Entity::Network::Vlan;

use Log::Log4perl "get_logger";
use Data::Dumper;
use NodemetricRule;
use Orchestrator;
use Action;

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
        
        my $clusterstate = $cluster->getAttr('name' => 'externalcluster_state');
        
        
        push @clusters, {
            route_base      => 'extclusters',
            link_activity   => 1,
            type            => 'External cluster',
            active          => 1,
            "state_$clusterstate"        => 1,
            cluster_id      => $cluster->getAttr(name => 'externalcluster_id'),
            cluster_name    => $cluster->getAttr(name => 'externalcluster_name'),
            cluster_desc    => $cluster->getAttr(name => 'externalcluster_desc'),
            nbnodes         => $nbnodes,
            nbnodesup       => $nbnodes,
        };
    }
    
    return \@clusters;
}

# retrieve data managers
sub _managers {
    my ($category) = @_; 
    my @datamanagers = Entity::ServiceProvider->findManager(category => $category);
    return @datamanagers;
}

# retrieve collector managers
sub _collector_managers {
    my @collectors = _managers('DataCollector');
    $log->debug('collectors: '.Dumper \@collectors);
    return @collectors;
}

# retrieve storage providers list
sub _storage_providers {
    my @storages = _managers('Storage');
    my %temp;
    foreach my $s (@storages) {
        $temp{ $s->{service_provider_id} } = 0;
    }

    my $sp = [];
    foreach my $id (keys %temp) {
        my $tmp = {};
        my $sp_entity = Entity::ServiceProvider->get(id => $id);
        $tmp->{id} = $id;
        $tmp->{name} = $sp_entity->toString();

        push (@$sp, $tmp);
    }
    return $sp;
}

# retrieve data managers
sub _cloudmanagers {
    my @cloudmanagers = Entity::ServiceProvider->findManager(category => 'Cloudmanager');
    return @cloudmanagers;
}

# retrieve hosts providers list
sub _host_providers {
    my @cloudmanagers = _managers('Cloudmanager');
    my %temp;
    foreach my $s (@cloudmanagers) {
        $temp{ $s->{service_provider_id} } = 0;
    }
    
    my $sp = [];
    foreach my $id (keys %temp) {
        my $tmp = {};
        my $sp_entity = Entity::ServiceProvider->get(id => $id);
        $tmp->{id} = $id;
        $tmp->{name} = $sp_entity->toString();
        
        push (@$sp, $tmp);
    }
    return $sp;
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

# return user groups containing at least one user

sub _users_groups {
    my ($selected) = @_;
    my @egroups = Entity::Gp->getGroups(hash => { gp_type => 'User' });
    my $groups  = [];

    foreach my $group (@egroups) {
        next if not $group->getSize();
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

# route to dynamically update owner user list

get '/clusters/users/:gpid' => sub {
    my $adm        = Administrator->new();
	my $loguser_id = $adm->{_rightchecker}->{user_id};
	my $loguser    = Entity::User->get(id => $loguser_id);
	 
    my $gp_id = param('gpid');
    my $gp_selected=Entity::Gp->get(id => param('gpid'));
    my @eusers= $gp_selected->getEntities();
    my $str="<option value=$loguser_id>current logged user</option>";
    foreach my $u (@eusers) {
        my $tmp = {};
	    $tmp->{user_firstname} = $u->getAttr(name=>'user_firstname');
	    $tmp->{user_lastname}  = $u->getAttr(name=>'user_lastname');
	    $tmp->{user_id}        = $u->getAttr(name=>'user_id');
	    $str .='<option value='.$tmp->{user_id}.'>'.$tmp->{user_firstname}.' '.$tmp->{user_lastname}.'</option>';
    }
    content_type('text/html'); 
    return $str;
};


# cluster add form display

get '/clusters/add' => sub {
    my $kanopya_cluster = Entity::ServiceProvider::Inside::Cluster->getCluster(hash=>{cluster_name => 'Kanopya'});
    my @kernels = Entity::Kernel->getKernels(hash => {});
    my @masterimages = Entity::Masterimage->getMasterimages(hash => {});
    my @hosts = Entity::Host->getHosts(hash => {});
    my $count = scalar @hosts;
    my $c =[];
    for (my $i=1; $i<=$count; $i++) {
        my $tmp->{nodes}=$i;
        push(@$c, $tmp);
    }
    my $kmodels = [];
    foreach my $k (@kernels) {
        my $tmp = {
            kernel_id => $k->getAttr( name => 'kernel_id'),
            kernel_name => $k->getAttr(name => 'kernel_version')
        };
        push (@$kmodels, $tmp);
    }
    my $masterimages_list = [];
    foreach my $s (@masterimages){
        my $tmp = {
            masterimage_id => $s->getAttr(name => 'masterimage_id'),
            masterimage_name => $s->getAttr(name => 'masterimage_name')
        };
        push (@$masterimages_list, $tmp);
    }

    # owner users list content is managed by javascript with
    # /clusters/users/:gpid

    # cloud managers list and parameters is managed by javascript with
    # /clusters/cloudmanagers/:hostproviderid and
    # /clusters/cloudmanagers/:hostproviderid/subform/:cloudmanagerid

    template 'form_addcluster', {
        title_page            => "Clusters - Cluster creation",
        kernels_list          => $kmodels,
        masterimages_list     => $masterimages_list,
        storageproviders_list => _storage_providers(),
        gp_list               => _users_groups(),
        hostproviders_list    => _host_providers(),
        nameserver            => $kanopya_cluster->getAttr(name => 'cluster_nameserver1'),
        
    }, { layout => '' };
};

# route to dynamically update cloud managers list

get '/clusters/cloudmanagers/:hostproviderid' => sub {
    my $id = param('hostproviderid');
    my $str = '';
    my @managers = _managers('Cloudmanager');
    foreach my $manager (@managers) {
        if($manager->{service_provider_id} eq $id) {
            $str .= '<option value="'.$manager->{id}.'">'.$manager->{name}.'</option>';
        }
    }
    
    content_type('text/html');
    return $str;
};

# route to dynamically update export managers list

get '/clusters/exportmanagers/:storageproviderid' => sub {
    my $id = param('storageproviderid');
    my $str = '';
    my @managers = _managers('Export');
    foreach my $manager (@managers) {
        if($manager->{service_provider_id} eq $id) {
            $str .= '<option value="'.$manager->{id}.'">'.$manager->{name}.'</option>';
        }
    }
    
    content_type('text/html');
    return $str;
};

# route to dynamically update cloud managers parameters 

get '/clusters/cloudmanagers/:hostproviderid/subform/:cloudmanagerid' => sub {
    my $storageid = param('hostproviderid');
    my $managerid = param('cloudmanagerid');
    my $sp = Entity::ServiceProvider->get(id => $storageid);
    my $cloudmanager = $sp->getManager(id => $managerid);
    if($cloudmanager->can('getConf')) {
        my $template;
        if($cloudmanager->isa('Entity::Component')) {
            my $componentdetail = $cloudmanager->getComponentAttr();
            $template = 'components/'.lc($componentdetail->{component_name}).$componentdetail->{component_version}.'_subform_addcluster.tt';
        } elsif($cloudmanager->isa('Entity::Connector')) {
            my $connectordetail = $cloudmanager->getConnectorType();
            $template = 'connectors/'.lc($connectordetail->{connector_name}).'_subform_addcluster.tt';
        }
        
        my $template_params = {};
            
        my $config = $cloudmanager->getConf();
        content_type('text/html');
        template "$template", $config, {layout => undef};
    } else {
        return 'not yet implemented';
    }
};

# route to dynamically update boot policies list 

get '/clusters/cloudmanagers/:hostproviderid/bootpolicies/:cloudmanagerid' => sub {
    my $storageid = param('hostproviderid');
    my $managerid = param('cloudmanagerid');
    my $sp = Entity::ServiceProvider->get(id => $storageid);
    my $cloudmanager = $sp->getManager(id => $managerid);
    my @bootpolicies = $cloudmanager->getBootPolicies();
    my $str = '';
    for my $boot (@bootpolicies) {
        $str .= "<option value=\"$boot\">$boot</option>";
    }
    content_type('text/html');
    return $str;
};

# cluster add processing

post '/clusters/add' => sub {
    my $adm = Administrator->new;
    my %parameters = params;

    my $sizeinbyte = General::convertToBytes(
        value => $parameters{disk_manager_param_systemimage_size}, 
        units => $parameters{systemimage_size_unit}
    );
    
    delete $parameters{systemimage_size_unit};
    $parameters{disk_manager_param_systemimage_size} = $sizeinbyte;

    my $persistent = param('cluster_si_persistent') eq 'checked' ? 1 : 0;
    $parameters{cluster_si_persistent} = $persistent;
 
    eval {
        Entity::ServiceProvider::Inside::Cluster->create(%parameters);
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

# external cluster add form display

get '/extclusters/add' => sub {
    
    template 'form_addexternalcluster', {
        title_page                  => "External Clusters - Add",
    }, { layout => '' };
};

# external cluster add processing

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

# clusters list display

get '/clusters' => sub {
    my $can_create;

    my $methods = Entity::ServiceProvider::Inside::Cluster->getPerms();
    if($methods->{'create'}->{'granted'}) {
        my @mi = Entity::Masterimage->getMasterimages(hash => {});
        if (scalar @mi){
            $can_create = 1;
        }
    }
    
    template 'clusters', {
        title_page         => 'Clusters - Clusters',
        clusters_list => [ @{_clusters()}, @{_externalclusters()} ],
        can_create => $can_create,
        
    }, { layout => 'main' };
};

# external clusters list display

get '/extclusters' => sub {
    my $can_create;

    template 'clusters', {
        title_page         => 'Clusters - External Clusters',
        clusters_list => _externalclusters(),
    }, { layout => 'main' };
};

# cluster detail display

get '/clusters/:clusterid' => sub {
    my $cluster_id = params->{clusterid};
    my $can_configure;
    my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
    my $methods = $ecluster->getPerms();
    my $minnode = $ecluster->getAttr(name => 'cluster_min_node');
    my $maxnode = $ecluster->getAttr(name => 'cluster_max_node');
    my $cluster_basehostname = $ecluster->getAttr(name=>'cluster_basehostname');
    my $masterimage_id = $ecluster->getAttr(name => 'masterimage_id');
    my $user_id = $ecluster->getAttr(name => 'user_id');
    my ($masterimage_name);
    if($masterimage_id) {
        my $masterimage = eval { Entity::Masterimage->get(id => $masterimage_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $masterimage_name = '-';
        } else {
            $masterimage_name =  $masterimage->getAttr(name => 'masterimage_name');
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
    
    # state info
    my ($cluster_state, $timestamp) = split ':', $ecluster->getAttr('name' => 'cluster_state');

    $can_configure = ($cluster_id == 1 or $cluster_state ne "down");

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

    while (my ($component_id, $comp) = each %$components) {
        my $compAtt = $comp->getComponentAttr();
        my $configure_component = $methods->{'configureComponents'}->{'granted'};
        my $link_remove = ($methods->{'removeComponent'}->{'granted'} or (not $active));

        if ($active and $cluster_id != 1) {
            $configure_component &= $comp->supportHotConfiguration();
        }

        push (@$comps, {
            component_id             => $component_id,
            component_name           => $compAtt->{component_name},
            component_version        => $compAtt->{component_version},
            component_category       => $compAtt->{component_category},
            cluster_id               => $cluster_id,
            link_configurecomponents => $configure_component,
            link_remove              => $link_remove
        });
    }

    # nodes list
    if($nbnodesup) {
        my $master_id = $ecluster->getMasterNodeId();
        while( my ($id, $n) = each %$hosts) {
            my $tmp = {
                host_id => $id,
                host_hostname => $n->getAttr(name => 'host_hostname'),
                host_internal_ip => $n->getAdminIp(),
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
                            ['goingin', 'starting'],      # match pregoingin, goingin and diplayed as starting
                            ['goingout', 'stopping'],     # match pregoingout, goingout and diplayed as stopping
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

    # Network interfacfes list
    my @networks_list = ();
    my @interfaces    = $ecluster->getNetworkInterfaces();
    for my $interface (@interfaces) {
        push @networks_list, {
            interface_id        => $interface->getAttr(name => 'entity_id'),
            interface_role_name => $interface->getRole->getAttr(name => 'interface_role_name'),
        }
    }

    my $link_stop = ! $link_start;

    template 'clusters_details', {
        title_page           => "Clusters - Cluster's overview",
        cluster_id           => $cluster_id,
        can_configure        => $can_configure,
        cluster_name         => $ecluster->getAttr(name => 'cluster_name'),
        cluster_desc         => $ecluster->getAttr(name => 'cluster_desc'),
        cluster_priority     => $ecluster->getAttr(name => 'cluster_priority'),
        cluster_domainname   => $ecluster->getAttr(name => 'cluster_domainname'),
        cluster_nameserver1  => $ecluster->getAttr(name => 'cluster_nameserver1'),
        cluster_nameserver2  => $ecluster->getAttr(name => 'cluster_nameserver2'),
        cluster_min_node     => $minnode,
        cluster_max_node     => $maxnode,
        cluster_basehostname => $cluster_basehostname,
        user_id             => $user_id,
        type               => $minnode == $maxnode ? 'Static cluster' : 'Dynamic cluster',
        masterimage_name   => $masterimage_name,
        masterimage_id     => $masterimage_id,
        kernel             => $kernel,
        networks_list      => \@networks_list,
        nbnetworks         => scalar(@networks_list),
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

# external cluster detail display

get '/extclusters/:clusterid' => sub {
    my $cluster_id = params->{clusterid};
    my $extcluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => $cluster_id);

    my $cluster_eval = Orchestrator::evalExtCluster(extcluster_id => $cluster_id,extcluster => $extcluster);
    
    # Connectors
    my @connectors = map { 
        {
            'connector_id'              => $_->getAttr(name => 'connector_id'),
            'link_configureconnector'   => 1,
            'link_remove'               => 1,
            %{$_->getConnectorType()},
        }
    } $extcluster->getConnectors();
    
    my @action_insts = Action->search(
        hash => {
            'action_service_provider_id' => $cluster_id
        }
    );
    
    my @actions;
    my @node_actions;
    my @cluster_actions;
    
    foreach my $action_inst (@action_insts) {
        my $hash = {
            'id'   => $action_inst->getAttr('name' => 'action_id'),
            'name' => $action_inst->getAttr('name' => 'action_name'),
            'type' => $action_inst->getParams()->{trigger_rule_type},
        };
        push @actions, $hash;
        
        if ($action_inst->getParams()->{trigger_rule_type} eq 'noderule') {
            push @node_actions, $hash;
        } elsif($action_inst->getParams()->{trigger_rule_type} eq 'clusterrule') {
            push @cluster_actions, $hash;
        }
    }
    
    my $order = {
        'up'        => 0,
        'warning'   => 1,
        'undef'     => 2,
        'down'      => 3,
        'disabled'  => 4,
    };
    
    my $disabled_nodes = $extcluster->getDisabledNodes();
    my $num_nodes_disabled = scalar @$disabled_nodes;
    
    my @nodes = (@$disabled_nodes,@{$cluster_eval->{nm_rule_nodes}});
    my @nodes_sort = sort {
        $order->{$a->{state}} cmp $order->{$b->{state}} 
    } @nodes;
    
    template 'extclusters_details', {
        title_page             => "External Clusters - Cluster's overview",
        active                 => 1,
        cluster_state          => $extcluster->getAttr(name => 'externalcluster_state'),
        cluster_id             => $cluster_id,
        cluster_name           => $extcluster->getAttr(name => 'externalcluster_name'),
        nodes_list             => \@nodes_sort,
        connectors_list        => \@connectors,
        actions_list           => \@actions,
        node_actions_list      => \@node_actions,
        cluster_actions_list   => \@cluster_actions,
        link_updatenodes       => 1,
        link_addconnector      => 1,
        link_delete            => 1,
        can_configure          => 1,
        nm_rule_enabled        => $cluster_eval->{nm_rule_enabled},
        nm_rule_undef          => $cluster_eval->{nm_rule_undef},
        num_noderule_verif     => $cluster_eval->{nm_rule_nok},
        num_nodes_nok          => $cluster_eval->{nm_rule_nodes_nok},
        cm_rule_ok             => $cluster_eval->{cm_rule_ok},
        cm_rule_enabled        => $cluster_eval->{cm_rule_enabled},
        cm_rule_undef          => $cluster_eval->{cm_rule_undef},
        num_cluster_rule_total => $cluster_eval->{cm_rule_total},
        num_clusterrule_verif  => $cluster_eval->{cm_rule_nok},
        num_nodes_disabled     => $num_nodes_disabled,

        
    }, { layout => 'main' };
};

# external cluster deletion processing

get '/extclusters/:clusterid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $cluster = Entity::ServiceProvider::Outside::Externalcluster->get(id => param('clusterid'));
        $cluster->delete();
    };
    if ($@) {
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

# cluster activation processing

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

# cluster deactivation processing

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

# cluster deletion processing

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

# cluster start processing

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

# cluster stop processing

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

# cluster forcestop processing

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

# cluster components addition form display

get '/clusters/:clusterid/components/add' => sub {
    my $adm = Administrator->new;
    my $cluster_id = param('clusterid');
    my ($ecluster, $esystemimage, $systemimage_components, $cluster_components);
    my $components = [];
    eval {
        $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => $cluster_id);
        $esystemimage = Entity::Systemimage->get(id => $ecluster->getAttr(name => 'masterimage_id'));
        $systemimage_components = $esystemimage->getProvidedComponents();
        
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

# cluster components addition processing

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

# cluster component deletion processing

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

# external cluster connect addition form display

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

# external cluster connectors addition form display

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

# external cluster connectors addition processing

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

### Network configuration

# cluster network addition form display

get '/clusters/:clusterid/network/add' => sub {
    my @rows = Entity::InterfaceRole->search(hash => {});
    my $interfaceroles = [];
    foreach my $row (@rows) {
        push @$interfaceroles, {
            interface_role_id   => $row->getAttr(name => 'entity_id'),
            interface_role_name => $row->getAttr(name => 'interface_role_name'),
            interface_role_desc => $row->getComment,
        };
    }

    @rows =  Entity::Network::Vlan->search(hash => {});
    my $vlans = [];
    foreach my $row (@rows) {
        push @$vlans, {
            vlan_id     => $row->getAttr(name => 'entity_id'),
            vlan_name   => $row->getAttr(name => 'network_name'),
            vlan_number => $row->getAttr(name => 'vlan_number'),
            vlan_desc   => $row->getComment,
        };
    }
 
    template 'form_addnetwork', {
        cluster_id          => param('clusterid'),
        interfaceroles_list => $interfaceroles,
        vlans_list          => $vlans,
    }, { layout => '' };
};

# cluster network addition form processing

post '/clusters/:clusterid/network/add' => sub {
    my $adm = Administrator->new;
    my %params = params;
    #$log->info(Dumper(%params));

    my @networks = ();
    for my $key (keys %params) {
        if ($key =~ /^vlan_id_/) {
            push @networks, $params{$key};
        }
    }

    eval {
        my $cluster = Entity::ServiceProvider->get(id => param('clusterid'));
        $cluster->addNetworkInterface(interface_role_id => param('interface_role_id'),
                                      networks          => \@networks);
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

# cluster network addition form processing

get '/clusters/:clusterid/network/:interfaceid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $cluster = Entity::ServiceProvider->get(id => param('clusterid'));
        $cluster->removeNetworkInterface(interface_id => param('interfaceid'));
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

# cluster node addition form display

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

# cluster node addition processing

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

# cluster node remove processing

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
        
        my $rep = $cluster->updateNodes( password => param('password') );
        
        $node_count       = $rep->{node_count};
        my $created_nodes = $rep->{created_nodes};
        
        foreach my $node (@$created_nodes){
            NodemetricRule::setAllRulesUndefForANode(
                cluster_id     => param('clusterid'),
                node_id        => $node->{id},
            );
        } 
        
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
