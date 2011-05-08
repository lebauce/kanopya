#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
package KanopyaUI::Monitoring;
use base 'KanopyaUI::CGI';

use Entity::Cluster;
use Entity::Motherboard;
use Data::Dumper;
use Log::Log4perl "get_logger";
use XML::Simple;
use JSON;

my $log = get_logger("webui");

my $conf_file_path = "/opt/kanopya/conf/monitor.conf";

# Build an array of html template hash for graphs associated to one target (cluster or node) and one set of indicators
sub graphs {
    my $self = shift;
    my %args = @_;
    
    my ($dir, $dir_alias, $subdir) = ($args{dir}, $args{dir_alias}, $args{subdir});
    my $target = $args{target};
    my $set = $args{set};
    my $ext = defined $args{ext} ? "_$args{ext}" : ""; 
    
    my @graphs = ();

    my $graph_name = "graph_" . "$target" . "_$set";
    if ( -e "$dir/$subdir/$graph_name$ext.png" ) {
        push @graphs, { CUSTOM_GRAPH_FILE => "$dir_alias/$subdir/$graph_name$ext.png",
                        HOUR_GRAPH_FILE => "$dir_alias/$subdir/$graph_name$ext" . "_hour.png",
                        DAY_GRAPH_FILE => "$dir_alias/$subdir/$graph_name$ext" . "_day.png",
                        };
    } else {
        # Here we manage graph of table when there is one graph per raw
        my $files = `ls $dir/$subdir/ | grep $graph_name`;
        my %indexes = ();
        foreach $file (split '\n', $files) {
            if ( $file =~ /$graph_name\.(.*)_.*/ ) { $indexes{$1} = undef }
        }
        foreach $index ( keys %indexes) {
            push @graphs,    {
                                CUSTOM_GRAPH_FILE => "$dir_alias/$subdir/$graph_name" . ".$index$ext.png",
                                HOUR_GRAPH_FILE => "$dir_alias/$subdir/$graph_name" . ".$index$ext" . "_hour.png",
                                DAY_GRAPH_FILE => "$dir_alias/$subdir/$graph_name" . ".$index$ext" . "_day.png",
                            }
        }
    }
    
    return @graphs;
}


sub getMonitorConf () {
    my $self = shift;
    
    my $conf = XMLin($conf_file_path);
    return $conf;
}

sub getMonitoredSets {
    my $self = shift;
    my %args = @_;

    return $self->{'adm'}{'manager'}{'monitor'}->getCollectedSets( cluster_id => $args{cluster_id} );
}

sub getAllSets {
    my $self = shift;
    
    return $self->{'adm'}{'manager'}{'monitor'}->getIndicatorSets();
}

#TODO passer par le monitor (et supprimer les bases inutiles) 
sub writeConf {
    my $self = shift;
    my %args = @_; 
    
    eval {
        my $config = XMLin($conf_file_path);

        my $conf = $self->getMonitorConf();
        $conf->{generate_graph} = { graph => $args{graphs_settings} };
        $conf->{monitor} = $args{collect_settings};
        
        $config->{conf} = [$conf];
        
        #my $xml_conf = XMLout($conf, RootName => 'conf');
        my $xml_conf = XMLout($config, RootName => 'config');
        
        open CONF_FILE, ">$conf_file_path" or die "Can't open configuration file for writing ($conf_file_path)";
        print CONF_FILE $xml_conf;
        close CONF_FILE;
    };
    if ($@) {
        return "Error while saving: $@";
    }
    return "configuration saved";
}

sub view_clustermonitoring : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl = $self->load_tmpl('Monitor/view_clustermonitoring.tmpl');
    $tmpl->param('titlepage' => "Clusters - Clusters");
    $tmpl->param('mClusters' => 1);
    $tmpl->param('submClusters' => 1);
    $tmpl->param('username' => $self->session->param('username'));
    
    my $cluster_id = $self->query()->param('cluster_id');
    
    #SETS
    my @sets = map { { id => $_->{label}, label => $_->{label} } } @{$self->getMonitoredSets( cluster_id => $cluster_id )};
    $tmpl->param('SETS' => \@sets);
    
    #NODES
    my $cluster = Entity::Cluster->get( id => $cluster_id );
    my $motherboards = $cluster->getMotherboards();
    my $masterId = $cluster->getMasterNodeId();
    my @nodes = map { { id => $_->getAttr(name=>'motherboard_id'),
                        name => $_->getInternalIP()->{ipv4_internal_address},
                        master => ($_->getAttr(name=>'motherboard_id') == $masterId) }
                    } values %$motherboards;
    
    $tmpl->param('NODES' => \@nodes);
    
    #CLUSTER
    $cluster_name = $cluster->getAttr( name => 'cluster_name' );
    $tmpl->param('CLUSTER_ID' => $cluster_id);
    $tmpl->param('CLUSTER_NAME' => $cluster_name);
    
    
    my $period = 'hour';
    #TODO retrieve from conf
    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp", "/graph", "monitor/graph");
    
    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
    $tmpl->param('NODECOUNT_GRAPH' => "$graph_dir_alias/$graph_subdir/$nodecount_graph");
    
    $tmpl->param('TITLEPAGE' => "Cluster's activity");
    #$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
    
    return $tmpl->output();
}

sub xml_graph_list : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl = $self->load_tmpl('Monitor/subview_clustermonitoring.tmpl');
    my $query = $self->query();
    my $set_name = $query->param('set');
    my $node_id = $query->param('node');
    my $period = $query->param('period') || "hour";
    
    my $cluster_id = $query->param('cluster_id');
    my $cluster = Entity::Cluster->get( id => $cluster_id );
    my $motherboards = $cluster->getMotherboards();
    my @all_ids = keys %$motherboards;
    my $cluster_name = $cluster->getAttr( name => 'cluster_name' ); 
    push @all_ids, $cluster_name;
    
    my @sets_name = map { $_->{label} } @{$self->getMonitoredSets( cluster_id => $cluster_id )};
    
    #TODO retrieve from conf
    my ($graph_dir, $graph_dir_alias, $graph_subdir) = ("/tmp", "/graph", "monitor/graph");
    
    my @graphs = ();    
    foreach my $node_id ( defined $node_id ? ($node_id) : @all_ids) {
        my @sets = ();
        my $node_ip = '';
        my $aggreg_ext = '';
        if ($node_id eq $cluster_name) {
            $aggreg_ext = '_avg';
            $node_ip = $cluster_name;    

#            my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
#            push @sets, {     set_name => 'nodecount', img_src => "$graph_dir_alias/$graph_subdir/$nodecount_graph"};

        } else {
            $node_ip = $motherboards->{$node_id}->getInternalIP()->{ipv4_internal_address};
        }
        
        foreach my $set ( defined $set_name ? ($set_name) : @sets_name ) {
            my $graph_name = "graph_" . $node_ip . "_" . $set . $aggreg_ext . "_" . $period . ".png";
            if ( -e  "$graph_dir/$graph_subdir/$graph_name" ) {
                push @sets, {     set_name => $set,
                                img_src => "$graph_dir_alias/$graph_subdir/$graph_name"};
            } else {
                push @sets, {     set_name => $set,
                                no_graph => 1};
            }
        }
        push @graphs, { id => $node_id, sets => \@sets};
    }
    $tmpl->param('GRAPHS' => \@graphs);
    
    my $nodecount_graph = "graph_" . $cluster_name . "_nodecount_" . $period . ".png";
    $tmpl->param('NODECOUNT_GRAPH' => "$graph_dir_alias/$graph_subdir/$nodecount_graph");
    
    
    return $tmpl->output();
    
}



=head2 save_clustermonitoring_settings
    
    Class : Public
    
    Desc :     Called by client to save monitoring settings for a cluster (collected sets and graphs options).
            Transform: query params (json) -> perl type (according to xml conf struct) -> xml (conf) 
    
=cut

sub save_clustermonitoring_settings : Runmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    
    my $cluster_id = $query->param('cluster_id');
    
    $log->info("Save monitoring settings for cluster $cluster_id");
    
    my @monit_sets = $query->param('collect_sets[]'); # array of set name

    my $graphs_settings_str = $query->param('graphs_settings'); # stringified array of hash
    my $graphs_settings = decode_json $graphs_settings_str;
        
    my $res = "conf saved";
    
    eval {
        $self->{'adm'}{'manager'}{'monitor'}->collectSets( cluster_id => $cluster_id, sets_name => \@monit_sets );
        $self->{'adm'}{'manager'}{'monitor'}->graphSettings( cluster_id => $cluster_id, graphs => $graphs_settings );
    };
    if ($@) {
        $res = "Error while saving: $@";
    }
    
    #my $res = $self->writeConf( graphs_settings => $graphs_settings, collect_settings => \@formated_monit_sets );
    
    return "$res";
}

sub save_monitoring_settings : Runmode {
    my $self = shift;
    my $errors = shift;
    my $query = $self->query();
    
    return "not implemented yet";
}

sub view_monitoring_settings : StartRunmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl = $self->load_tmpl('Monitor/view_monitoring_settings.tmpl');
    
    #TODO put this in Monitor (method for retrieve conf)
    my $conf = $self->getMonitorConf();
    
    my $all_sets = $self->getAllSets();

    my @sets = ();
    foreach $set (@$all_sets) {
        my @all_ds = ();
        foreach $ds ( @{ General::getAsArrayRef( data => $set, tag => 'ds' ) } ) {
            push @all_ds, { ds_name => $ds->{label}, oid => $ds->{oid}};
        }
         
        push @sets, {    label => $set->{label},
                        provider_name => ($set->{data_provider} =~ /(.*)Provider/) ? $1 : ($set->{data_provider} ? $set->{data_provider} : "Snmp"),
                        component => $set->{component},
                        ds_type => ucfirst lc $set->{ds_type},
                        is_table => defined $set->{table_oid},
                        table_oid => $set->{table_oid},
                        ds => \@all_ds};
    }
    $tmpl->param('SETS' => \@sets);
    
    $tmpl->param(    'TIME_STEP' => $conf->{time_step},
                    'PERIOD' => $conf->{period},
                    'RRD_BASE_DIR'=> $conf->{rrd_base_dir},
                    'GRAPH_DIR'=> $conf->{graph_dir} );
    
    $tmpl->param('TITLEPAGE' => "Monitoring settings");
    $tmpl->param('MSETTINGS' => 1);
    $tmpl->param('SUBMMONITOR' => 1);
    
    return $tmpl->output();
}

=head2 view_clustermonitoring_settings
    
    Class : Public
    
    Desc :     build html page of monitoring settings for client.
            Tranform: conf (xml) -> perl type (according to html template) -> html
    
    Args :
    
    Return :
    
=cut

sub view_clustermonitoring_settings : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl = $self->load_tmpl('Monitor/view_clustermonitoring_settings.tmpl');
    my $query = $self->query();
    
    my $collect_sets = $self->getMonitoredSets( cluster_id => $query->param('cluster_id') );
    my $all_sets = $self->getAllSets();
    my @sets = ();
    foreach $set (@$all_sets) {
        my @all_ds = ();
        my $graph_settings = $self->{'adm'}{'manager'}{'monitor'}->getGraphSettings(  cluster_id => $query->param('cluster_id'),
                                                                                        set_name => $set->{label} );
        my @ds_on_graph = defined $graph_settings ? split(",", $graph_settings->{ds_label}) : ();
        my $is_graphed = scalar @ds_on_graph;
        foreach $ds ( @{ General::getAsArrayRef( data => $set, tag => 'ds' ) } ) {
            push @all_ds, {
                            ds_name => $ds->{label},
                            on_graph => scalar ( grep { $_ eq $ds->{label} || $_ eq 'ALL'} @ds_on_graph ),
                            };
        }
         
        push @sets, {    label => $set->{label},
                        collected => scalar ( grep { $_->{label} eq $set->{label} } @$collect_sets ),
                        graphed => $is_graphed,
                        is_table => defined $set->{table_oid},
                        
                        graph_type => defined $graph_settings ? $graph_settings->{graph_type} || 'line' : 'line',
                        percent => defined $graph_settings ? $graph_settings->{percent} || 'no' : 'no',
                        with_total => defined $graph_settings ? $graph_settings->{with_total} || 'no' : 'no',
                        all_in_one => defined $graph_settings ? $graph_settings->{all_in_one} || 'no' : 'no',
                                                    
                        ds => \@all_ds,
                    };
    }
    $tmpl->param('SETS' => \@sets);
    $tmpl->param('CLUSTER_ID' => $query->param('cluster_id'));
    $tmpl->param('TITLEPAGE' => "Cluster monitoring settings");
    $tmpl->param('MCLUSTERS' => 1);
    $tmpl->param('SUBMCLUSTERS' => 1);
    
    return $tmpl->output();
}


sub process_customgraph : Runmode {
    my $self = shift;
    
     my $query = $self->query();
     
     my ($date_start, $time_start, $date_end, $time_end) = ( $query->param('date_start'), $query->param('time_start'),
                                                              $query->param('date_end'), $query->param('time_end') );
     
     # we write custom range in a specific file which will be read by Monitor::Retriever at the next graph generation iteration
     `echo "$date_start $time_start,$date_end $time_end" > /tmp/gen_graph_custom.conf`;
     
#     use Monitor::Retriever;
#     my $monitor = Monitor::Retriever->new();
#     my %graph_infos = $monitor->graphFromConf();
    
     $self->redirect('/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id='.$query->param('cluster_id') . "&custom" . "#monitoring");
}

1;
