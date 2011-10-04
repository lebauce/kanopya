package Clusters;

use Dancer ':syntax';

use Entity::Cluster;
use Entity::Motherboard;
use Entity::Systemimage;
use Entity::Kernel;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

sub _clusters {

    my @eclusters = Entity::Cluster->getClusters(hash => {});
    my $clusters = [];
    my $clusters_list;
    my $can_create;

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

             my $cluster_state = $n->getAttr('name' => 'cluster_state');
            for my $state ('up', 'starting', 'stopping', 'down', 'broken') {
                if ( $cluster_state =~ $state ) {
                    $tmp->{"state_$state"} = 1;
                }
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

    #$tmpl->param('titlepage' => "Clusters - Clusters");
    #$tmpl->param('mClusters' => 1);
    #$tmpl->param('submClusters' => 1);
    #$tmpl->param('username' => $self->session->param('username'));

sub _clusterdetails {

    # header / menu variables

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
    $tmpl->param('cluster_domainname' => $ecluster->getAttr(name => 'cluster_domainname'));
    $tmpl->param('cluster_nameserver' => $ecluster->getAttr(name => 'cluster_nameserver'));

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
        my $esystemimage = eval { Entity::Systemimage->get(id => $systemimage_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $tmpl->param('systemimage_name' => '-');
            $tmpl->param('systemimage_active' => '-');
        } else {
            $tmpl->param('systemimage_name' =>  $esystemimage->getAttr(name => 'systemimage_name'));
            $tmpl->param('systemimage_active' => $esystemimage->getAttr('name' => 'active'));
        }
    }

    my $kernel_id = $ecluster->getAttr(name =>'kernel_id');
    if($kernel_id) {
        my $ekernel = eval { Entity::Kernel->get(id => $kernel_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $tmpl->param('kernel' =>'-');
        } else {
            $tmpl->param('kernel' => $ekernel->getAttr(name => 'kernel_version'));
        }
    } else {
        $tmpl->param('kernel' => 'no specific kernel');
    }

    my $publicips = $ecluster->getPublicIps();
    $tmpl->param('publicip_list' => $publicips);
    $tmpl->param('nbpublicips' => scalar(@$publicips)+1);

    # state info
    my ($cluster_state, $timestamp) = split ':', $ecluster->getAttr('name' => 'cluster_state');
    for my $state ('up', 'starting', 'stopping', 'down', 'broken') {
        if ( $cluster_state =~ $state ) {
            $tmpl->param("state_$state" => 1);
        }
    }
    $tmpl->param("state_time" => $self->timestamp_format( timestamp => $timestamp ));
    
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
            $tmpl->param('link_deactivate' => 1);
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
        if(not $methods->{'configureComponents'}->{'granted'} ) {
                $comphash->{'link_configureComponents'} = 0;
        } else { $comphash->{'link_configureComponents'} = 1;}
        if(not $methods->{'removeComponent'}->{'granted'} ) {
                $comphash->{link_remove} = 0;
        } else { $comphash->{link_remove} = not $active;}


        push (@$comps, $comphash);
    }
    $tmpl->param('nbcomponents' => scalar(@$comps)+1);
    $tmpl->param('components_list' => $comps);

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
            $tmp->{"state_time"} = $self->timestamp_format( timestamp => $time_stamp );

            push @$nodes, $tmp;
        }
    }

    if($tmpl->param('link_start')) {
        $tmpl->param('link_stop' => 0);
    } else { $tmpl->param('link_stop' => 1); }

    $tmpl->param('nodes_list' => $nodes);
    if(not $methods->{'update'}->{'granted'} ) { $tmpl->param('link_edit' => 0); }
    if(not $methods->{'remove'}->{'granted'} ) { $tmpl->param('link_delete' => 0); }
    if(not $methods->{'activate'}->{'granted'} ) { $tmpl->param('link_activate' => 0); }
    if(not $methods->{'start'}->{'granted'} ) { $tmpl->param('link_start' => 0); }
    # TODO identifier le cluster d'admin autrement que $cluster_id == 1
    if(not $methods->{'stop'}->{'granted'} or $cluster_id == 1) { $tmpl->param('link_stop' => 0); }

    #return "granted : $methods->{'addComponent'}->{'granted'} and active : ".$ecluster->getAttr('name' => 'active');

    if((not $methods->{'addComponent'}->{'granted'}) || $ecluster->getAttr('name' => 'active') ) {
        $tmpl->param('link_addcomponent' => 0);
    }
    else {
        $tmpl->param('link_addcomponent' => 1);
    }

    return $tmpl->output();
}

    #$tmpl->param('titlepage' => "Cluster's overview");
    #$tmpl->param('mClusters' => 1);
    #$tmpl->param('submClusters' => 1);
    #$tmpl->param('username' => $self->session->param('username'));

get '/clusters' => sub {
    my $can_create;

    my $methods = Entity::Cluster->getPerms();
    if($methods->{'create'}->{'granted'}) {
        my @si = Entity::Systemimage->getSystemimages(hash => {});
        if (scalar @si){
            $can_create = 1
        }
    }

    template 'clusters', {
        title_page         => 'Clusters - Clusters',
        clusters_list => _clusters(),
        can_create => $can_create,
    };
};

sub _clusterdetails : Runmode {
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
    $tmpl->param('cluster_domainname' => $ecluster->getAttr(name => 'cluster_domainname'));
    $tmpl->param('cluster_nameserver' => $ecluster->getAttr(name => 'cluster_nameserver'));

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
        my $esystemimage = eval { Entity::Systemimage->get(id => $systemimage_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $tmpl->param('systemimage_name' => '-');
            $tmpl->param('systemimage_active' => '-');
        } else {
            $tmpl->param('systemimage_name' =>  $esystemimage->getAttr(name => 'systemimage_name'));
            $tmpl->param('systemimage_active' => $esystemimage->getAttr('name' => 'active'));
        }
    }

    my $kernel_id = $ecluster->getAttr(name =>'kernel_id');
    if($kernel_id) {
        my $ekernel = eval { Entity::Kernel->get(id => $kernel_id) };
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $tmpl->param('kernel' =>'-');
        } else {
            $tmpl->param('kernel' => $ekernel->getAttr(name => 'kernel_version'));
        }
    } else {
        $tmpl->param('kernel' => 'no specific kernel');
    }

    my $publicips = $ecluster->getPublicIps();
    $tmpl->param('publicip_list' => $publicips);
    $tmpl->param('nbpublicips' => scalar(@$publicips)+1);

    # state info
    my ($cluster_state, $timestamp) = split ':', $ecluster->getAttr('name' => 'cluster_state');
    for my $state ('up', 'starting', 'stopping', 'down', 'broken') {
        if ( $cluster_state =~ $state ) {
            $tmpl->param("state_$state" => 1);
        }
    }
    $tmpl->param("state_time" => $self->timestamp_format( timestamp => $timestamp ));
    
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
            $tmpl->param('link_deactivate' => 1);
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
        if(not $methods->{'configureComponents'}->{'granted'} ) {
                $comphash->{'link_configureComponents'} = 0;
        } else { $comphash->{'link_configureComponents'} = 1;}
        if(not $methods->{'removeComponent'}->{'granted'} ) {
                $comphash->{link_remove} = 0;
        } else { $comphash->{link_remove} = not $active;}


        push (@$comps, $comphash);
    }
    $tmpl->param('nbcomponents' => scalar(@$comps)+1);
    $tmpl->param('components_list' => $comps);

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
            $tmp->{"state_time"} = $self->timestamp_format( timestamp => $time_stamp );

            push @$nodes, $tmp;
        }
    }

    if($tmpl->param('link_start')) {
        $tmpl->param('link_stop' => 0);
    } else { $tmpl->param('link_stop' => 1); }

    $tmpl->param('nodes_list' => $nodes);
    if(not $methods->{'update'}->{'granted'} ) { $tmpl->param('link_edit' => 0); }
    if(not $methods->{'remove'}->{'granted'} ) { $tmpl->param('link_delete' => 0); }
    if(not $methods->{'activate'}->{'granted'} ) { $tmpl->param('link_activate' => 0); }
    if(not $methods->{'start'}->{'granted'} ) { $tmpl->param('link_start' => 0); }
    # TODO identifier le cluster d'admin autrement que $cluster_id == 1
    if(not $methods->{'stop'}->{'granted'} or $cluster_id == 1) { $tmpl->param('link_stop' => 0); }

    #return "granted : $methods->{'addComponent'}->{'granted'} and active : ".$ecluster->getAttr('name' => 'active');

    if((not $methods->{'addComponent'}->{'granted'}) || $ecluster->getAttr('name' => 'active') ) {
        $tmpl->param('link_addcomponent' => 0);
    }
    else {
        $tmpl->param('link_addcomponent' => 1);
    }

    return $tmpl->output();
}
