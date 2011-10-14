package Monitoring;

use Dancer ':syntax'; 

use Log::Log4perl "get_logger";

my $log = get_logger("webui");

prefix '/architectures';

sub _getMonitoredSets {
    my %args = @_;
    my $adm    = Administrator->new();

    return $adm->{'manager'}{'monitor'}->getCollectedSets( cluster_id => $args{cluster_id} );
}

get '/clusters/:clusterid/monitoring/toto' => sub {

    my $period = 'day';
    my $cluster_name = 'adm';


    content_type('text/xml');
    return '<data><tutu>' . 'pouet' . '</tutu></data>';
    
    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp/monitor/graph", "/images/graphs", "");
    
    # node count graph
    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
    my $nodecount_graph_path = "$graph_dir_alias/$nodecount_graph";
    
    template 'subview_clustermonitoring', {
        nodecount_graph => $nodecount_graph_path, 
        graphs => [ { id => 1, sets => [ { set_name => "AAAA SETTTTTT", img_src => "/images/graphs/graph_consumption_hour.png"} ] } ],
    };
    
#    content_type('text/xml');
#    return '<data>' . "YOUPI" . '</data>';
#    
#    my $set_name = $query->param('set');
#    my $node_id = $query->param('node');
#    my $period = $query->param('period') || "hour";
#    
#    my $cluster_id = $query->param('cluster_id');
#    my $cluster = Entity::Cluster->get( id => $cluster_id );
#    my $motherboards = $cluster->getMotherboards();
#    my @all_ids = keys %$motherboards;
#    my $cluster_name = $cluster->getAttr( name => 'cluster_name' ); 
#    push @all_ids, $cluster_name;
#    
#    my @sets_name = map { $_->{label} } @{$self->getMonitoredSets( cluster_id => $cluster_id )};
#    
#    #TODO retrieve from conf
#    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp", "/graph", "monitor/graph");
#    
#    my @graphs = ();    
#    foreach my $node_id ( defined $node_id ? ($node_id) : @all_ids) {
#        my @sets = ();
#        my $node_ip = '';
#        my $aggreg_ext = '';
#        if ($node_id eq $cluster_name) {
#            $aggreg_ext = '_avg';
#            $node_ip = $cluster_name;    
#
##            my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
##            push @sets, {     set_name => 'nodecount', img_src => "$graph_dir_alias/$graph_subdir/$nodecount_graph"};
#
#        } else {
#            $node_ip = $motherboards->{$node_id}->getInternalIP()->{ipv4_internal_address};
#        }
#        
#        foreach my $set ( defined $set_name ? ($set_name) : @sets_name ) {
#            my $graph_name = "graph_" . $node_ip . "_" . $set . $aggreg_ext . "_" . $period . ".png";
#            if ( -e  "$graph_dir/$graph_subdir/$graph_name" ) {
#                push @sets, {     set_name => $set,
#                                img_src => "$graph_dir_alias/$graph_subdir/$graph_name"};
#            } else {
#                push @sets, {     set_name => $set,
#                                no_graph => 1};
#            }
#        }
#        push @graphs, { id => $node_id, sets => \@sets};
#    }
#    $tmpl->param('GRAPHS' => \@graphs);
#    
#    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
#    $tmpl->param('NODECOUNT_GRAPH' => "$graph_dir_alias/$graph_subdir/$nodecount_graph");
    
    
};

get '/clusters/:clusterid/monitoring' => sub {
    my $cluster_id    = params->{clusterid} || 0;

    #SETS
    my @sets = map { { id => $_->{label}, label => $_->{label} } } @{_getMonitoredSets( cluster_id => $cluster_id )};
    
    #NODES
    my $cluster = Entity::Cluster->get( id => $cluster_id );
    my $motherboards = $cluster->getMotherboards();
    my $masterId = $cluster->getMasterNodeId();
    my @nodes = map { { id => $_->getAttr(name=>'motherboard_id'),
                        name => $_->getInternalIP()->{ipv4_internal_address},
                        master => ($_->getAttr(name=>'motherboard_id') == $masterId) }
                    } values %$motherboards;
    
    #CLUSTER
    my $cluster_name = $cluster->getAttr( name => 'cluster_name' );
    
    my $period = 'hour';
    #TODO retrieve from conf
    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp/monitor/graph", "/images/graphs", "");
    
    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
    my $nodecount_graph_path = "$graph_dir_alias/$nodecount_graph";
    

    template 'view_clustermonitoring', {
        title_page                 => "Cluster's activity",
        nodecount_graph => $nodecount_graph_path,
        cluster_id      => $cluster_id,
        cluster_name    => $cluster_name,
        nodes => \@nodes,
        sets => \@sets,
    };
};


1;
