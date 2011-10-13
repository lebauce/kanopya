package Clusters;

use Dancer ':syntax';

use Administrator;
use Entity::Cluster;
use Entity::Motherboard;
use Entity::Systemimage;
use Entity::Kernel;
use Log::Log4perl "get_logger";

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

    my @eclusters = Entity::Cluster->getClusters(hash => {});
    my $clusters = [];
    my $clusters_list;
    my $can_create;

    foreach my $n (@eclusters){
        my $tmp = {
            link_activity => 0,
            cluster_id    => $n->getAttr(name => 'cluster_id'),
            cluster_name  => $n->getAttr(name => 'cluster_name')
        };

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

get '/clusters/add' => sub {

my $kanopya_cluster = Entity::Cluster->getCluster(hash=>{cluster_name => 'adm'});
    my @ekernels = Entity::Kernel->getKernels(hash => {});
    my @esystemimages_forshared = Entity::Systemimage->getSystemimages(hash => {systemimage_dedicated => {'!=',1}});
    my @esystemimages_fordedicated = Entity::Systemimage->getSystemimages(hash => {active => 0});
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
        'nameserver'                => $kanopya_cluster->getAttr(name => 'cluster_nameserver'),
    };
};

post '/clusters/add' => sub {

};

get '/clusters' => sub {
    my $can_create;

    my $methods = Entity::Cluster->getPerms();
    if($methods->{'create'}->{'granted'}) {
        my @si = Entity::Systemimage->getSystemimages(hash => {});
        if (scalar @si){
            $can_create = 1;
        }
    }
    
    #TEMPORARY testing
    $can_create = 1;
    
    template 'clusters', {
        title_page         => 'Clusters - Clusters',
        clusters_list => _clusters(),
        can_create => $can_create,
    };
};

get '/clusters/:clusterid' => sub {
    my $cluster_id = params->{clusterid};
    my $ecluster = Entity::Cluster->get(id => $cluster_id);
    my $methods = $ecluster->getPerms();

    my $minnode = $ecluster->getAttr(name => 'cluster_min_node');
    my $maxnode = $ecluster->getAttr(name => 'cluster_max_node');

    my $systemimage_id = $ecluster->getAttr(name => 'systemimage_id');
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
    
    my $motherboards = $ecluster->getMotherboards(administrator => Administrator->new);
    my $nbnodesup = scalar(keys(%$motherboards));
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

    while( my ($instance_id, $comp) = each %$components) {
        my $comphash = {};
        my $compAtt = $comp->getComponentAttr();
        $comphash->{component_instance_id} = $instance_id;
        $comphash->{component_name} = $compAtt->{component_name};
        $comphash->{component_version} = $compAtt->{component_version};
        $comphash->{component_category} = $compAtt->{component_category};
        $comphash->{cluster_id} = $cluster_id;
        if(not $methods->{'configureComponents'}->{'granted'} ) {
                $comphash->{'link_configureComponents'} = 0;
        } else { $comphash->{'link_configureComponents'} = 1;}
        if(not $methods->{'removeComponent'}->{'granted'} ) {
                $comphash->{link_remove} = 0;
        } else { $comphash->{link_remove} = not $active;}


        push (@$comps, $comphash);
    }

    # nodes list
    if($nbnodesup) {
        my $master_id = $ecluster->getMasterNodeId();
        while( my ($id, $n) = each %$motherboards) {
            my $tmp = {
                motherboard_id => $id,
                motherboard_hostname => $n->getAttr(name => 'motherboard_hostname'),
                motherboard_internal_ip => $n->getInternalIP()->{ipv4_internal_address},
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
        cluster_name       => $ecluster->getAttr(name => 'cluster_name'),
        cluster_desc       => $ecluster->getAttr(name => 'cluster_desc'),
        cluster_priority   => $ecluster->getAttr(name => 'cluster_priority'),
        cluster_domainname => $ecluster->getAttr(name => 'cluster_domainname'),
        cluster_nameserver => $ecluster->getAttr(name => 'cluster_nameserver'),
        cluster_min_node   => $minnode,
        cluster_max_node   => $maxnode,
        type               => $minnode == $maxnode ? 'Static cluster' : 'Dynamic cluster',
        systemimage_name   => $systemimage_name,
        systemimage_active => $systemimage_active,
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
        link_start         => $methods->{'start'}->{'granted'} ? $link_start : 0,
        link_stop          => (not $methods->{'stop'}->{'granted'}) || ($cluster_id == 1) ? 0 : 1,
        link_edit          => $methods->{'update'}->{'granted'}, 
        link_addnode       => $methods->{'addnode'}->{'granted'} ? $link_addnode : 0,
        link_addcomponent  => $methods->{'addComponent'}->{'granted'} || $active ? 0 : 1,
        can_setperm        => $methods->{'setperm'}->{'granted'},        
                       
     };
};


get '/clusters/:clusterid/components/add' => sub {
    my $cluster_id = params->{clusterid};
    my $ecluster = Entity::Cluster->get(id => $cluster_id);
    my $methods = $ecluster->getPerms();

    template 'form_addcomponenttocluster', {
        title_page         => "Clusters - Cluster's add component",
        cluster_id         => $cluster_id,
    };
};

post '/clusters/:clusterid/addcomponentoncluster' => sub {

};

get '/clusters/:clusterid/publicips/add' => sub {
    my $cluster_id = params->{clusterid};
    my $ecluster = Entity::Cluster->get(id => $cluster_id);
    my $methods = $ecluster->getPerms();

    template 'form_setpubliciptocluster', {
        title_page         => "Clusters - Cluster's add component",
        cluster_id         => $cluster_id,
    };
};

post '/clusters/:clusterid/publicips/add' => sub {
    my $cluster_id = params->{clusterid};
    my $ecluster = Entity::Cluster->get(id => $cluster_id);
    my $methods = $ecluster->getPerms();

    redirect '/architectures/clusters';
    
};

1;
