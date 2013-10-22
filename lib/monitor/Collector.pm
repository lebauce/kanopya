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
=pod
=begin classdoc

TODO

=end classdoc
=cut

package Collector;
use base Daemon::Pooling;

use strict;
use warnings;

use BaseDB;
use Entity::ServiceProvider::Cluster;
use General;
use Kanopya::Config;
use Entity::Host;
use Message;
use Retriever;

use XML::Simple;
use Net::Ping;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

Load monitor configuration and do the BaseDB authentication.

@constructor

=end classdoc
=cut

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(confkey => 'monitor');

    # Create monitor dirs if required
    my @dir_path = split '/', $self->{config}->{rrd_base_directory};
    my $dir = substr($self->{config}->{rrd_base_directory}, 0, 1) eq '/' ? "/" : "";
    while (scalar @dir_path) {
        $dir .= (shift @dir_path) . "/";
        mkdir $dir;
    }

    # Register the method to call every loop
    $self->registerPollingMethod(callback => \&update);

    return $self;
}

sub retrieveHostsByCluster {
    my $self = shift;

    my %hosts_by_cluster;

    my @clusters = Entity::ServiceProvider::Cluster->search(hash => {}, prefetch => [ 'nodes.host' ]);
    foreach my $cluster (@clusters) {
        my @components = $cluster->getComponents(category => 'all');
        my @components_name = map { $_->component_type->component_name } @components;

        my %mb_info;
        foreach my $mb ($cluster->getHosts()) {
            $mb_info{$mb->node->node_hostname} = {
                ip         => $mb->adminIp,
                state      => $mb->host_state,
                components => \@components_name
            };
        }
        $hosts_by_cluster{$cluster->cluster_name} = \%mb_info;
    }
    return %hosts_by_cluster;
}

sub getClusterHostsInfo {
    my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    #TODO ne pas récupérer tous les clusters mais ajouter un paramètre optionnel à retrieveHostsByCluster pour ne récupérer que certains clusters
    my %hosts_by_cluster = $self->retrieveHostsByCluster();
    return $hosts_by_cluster{ $cluster };
}


=pod
=begin classdoc

Aggregate a list of hash into one hash by applying desired function (sum, mean).

@param hash_list array ref: list of hashes to aggregate. [ { p1 => v11, p2 => v12}, { p1 => v21, p2 => v22} ]

@optional f "mean", "sum" : aggregation function. If not defined, f() = sum().

@return The aggregated hash. ( p1 => f(v11,v21), p2 => f(v12,v22) )

=end classdoc
=cut

sub aggregate {
    my $self = shift;
    my %args = @_;
    
    my %res = ();
    my $nb_keys;
    my $nb_elems = 0;
    foreach my $data (@{ $args{hash_list} })
    {
        if ( ref $data eq "HASH"  ) {
            $nb_elems++;
            if ( 0 == scalar keys %res ) {
                %res = %$data;
                $nb_keys = scalar keys %res;
            } else {
                if (  $nb_keys != scalar keys %$data) {
                    $log->warning("Hashes to aggregate have not the same number of keys. => mean computing will be incorrect.");
                }
                while ( my ($key, $value) = each %$data ) {
                        # TODO ! something is wrong here. do a better undef values management!
                        if ( defined $value ) {
                            $res{ $key } += $value;
                        } else {
                            $res{ $key } += 0;
                        }
                }
            }
        }
    }
    
    if ( defined $args{f} && $args{f} eq "mean" && $nb_elems > 0) {
        for my $key (keys %res) {
            if ( defined $res{$key} ) {
                $res{$key} /= $nb_elems;
            } else {
                $res{$key} = 0;
            }
        }
    }
    
    return %res;
}


=pod
=begin classdoc

Instanciate a RRDTool object and create a rrd

@param dsname_list : the list of var name to store in the rrd

@param ds_type : the type of var ( GAUGE, COUNTER, DERIVE, ABSOLUTE )

@param file : the name of the rrd file to create

@optional time_step: overload monitoring time_step (conf)

@return The RRDTool object

=end classdoc
=cut

sub createRRD {
    my $self = shift;
    my %args = @_;

    $log->info("## CREATE RRD : '$args{file}' ##");

    my $time_step   = $args{time_step} || $self->{config}->{time_step};
    my $dsname_list = $args{dsname_list};
    my $set_def     = Indicatorset->findFromLabel(label => $args{set_name});
    my $ds_list     = General::getAsHashRef( data => $set_def, tag => 'ds', key => 'label');

    my $rrd = Retriever->getRRD(file => $args{file}, rrd_base_dir => $self->{config}->{rrd_base_directory});

    my $raws = $self->{config}->{storage_duration} / $time_step;

    my @rrd_params = ('step', $time_step,
                      'archive',  { rows    => $raws });
    for my $name ( @$dsname_list ) {
        push @rrd_params, (
                            'data_source' => {
                                name      => $name,
                                type      => $args{ds_type},
                                min        => $ds_list->{$name}{min},
                                max        => $ds_list->{$name}{max} 
                            },
        );
    }

    # Create a round-robin database
    $rrd->create( @rrd_params );
    
    return $rrd;
}


=pod
=begin classdoc

Delete rrd

@param set_name

@param host_name

=end classdoc
=cut

sub deleteRRD {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'set_name', 'host_name' ]);

    my $set_name = $args{set_name};
    my $rrd_name = Retriever->rrdName(set_name => $args{set_name}, host_name => $args{host_name});
    my $rrdfile_name = "$rrd_name.rrd";
    my $cmd = 'rm ' . $self->{config}->{rrd_base_directory} . '/' . $rrdfile_name;
    system ($cmd);
}


=pod
=begin classdoc

Store values in rrd. If rrd doesn't exist, then create it

@param time the time associated with values retrieving

@param rrd_name the name of the rrd

@param data hash ref { var_name => value }

@param ds_type the type of data sources (vars)

@optional time_step used if create rrd, to overload monitoring time_step (conf)

@return the hash of values as stored in rrd

=end classdoc
=cut

sub updateRRD {
    my $self = shift;
    my %args = @_;
    
    my $time = $args{time};
    my $rrdfile_name = "$args{rrd_name}.rrd";
    my $rrd = Retriever->getRRD(file => $rrdfile_name, rrd_base_dir => $self->{config}->{rrd_base_directory});

    eval {
        $rrd->updatev( time => $time, values =>  $args{data} );
    };
    # we catch error to handle unexisting file or configuration change.
    # if happens then we create the rrd file. All stored data will be lost.
    if ($@) {
        my $error = $@;
        
        if ( $error =~ "illegal attempt to update using time") {
            $log->error( "$error" );
        }
        # TODO check the error
        else {
            $log->info("=> update : unexisting RRD file or set definition changed in conf => we (re)create it ($rrdfile_name).\n (Reason: $error)");
            my @dsname_list = keys %{ $args{data} };
            $rrd = $self->createRRD( 
                       file        => $rrdfile_name,
                       dsname_list => \@dsname_list,
                       ds_type     => $args{ds_type},
                       set_name    => $args{set_name},
                       time_step   => $args{time_step},
                   );

            $rrd->update( time => $time, values =>  $args{data} );
        }
    } 

    ################################################
    # Retrieve last values as it's stored in rrd
    ################################################
    my %stored_values = ();
    if ( $args{ds_type} eq 'GAUGE' ) {
        %stored_values = %{ $args{data} };
    }
    else {
        #TODO check if we really retrieve the last value in all cases
        $rrd->fetch_start(start => $time - $self->{config}->{time_step});

        my ($t, @values) = $rrd->fetch_next();
        my @ds_names = @{ $rrd->{fetch_ds_names} };
        foreach my $i ( 0 .. $#ds_names ) {
            $stored_values{ $ds_names[$i] } = $values[$i];
        }
    }
    return %stored_values;
}


=pod
=begin classdoc

For a host, retrieve value of all monitored data (var defined in conf)
and store them in corresponding rrd

@param host_name the host name

@param components array ref of components name on this host.

@param host_state current state of the host

=end classdoc
=cut

sub updateHostData {
    my $self = shift;
    my %args = @_;

    my $start_time = time();
    my $host = $args{host};
    my $host_name = $host->node->node_hostname;
    my $host_ip = $host->adminIp;
    my $host_reachable = 1;
    my %all_values = ();
    my $error_happened = 0;
    my %providers = ();
    my $error;

    eval {
        #For each required set of indicators
        SET:
        foreach my $set ( @{ $args{sets} } ) {
            #############################################################
            # Skip this set if associated component is not on this host #
            #############################################################
            if (defined $set->indicatorset_component &&
                ! exists $args{components}->{ $set->indicatorset_component }) {
                $log->info("[$host_name] No component '$set->indicator_component' to monitor on this host");
                next SET;
            }

            # Skip set if collect is done by an external process
            next SET if ($set->indicatorset_provider eq 'External');

            ###################################################
            # Build the required var map: ( var_name => oid ) #
            ###################################################
            my %var_map = map { $_->indicator_name => $_->indicator_oid } $set->indicators;

            my ($time, $update_values);
            my $retrieve_set_time;
            my $provider_class;
            eval {
                #################################
                # Get the specific DataProvider #
                #################################
                $provider_class = $set->indicatorset_provider || "SnmpProvider";
                my $data_provider = $providers{$provider_class};
                if (not defined $data_provider) {
                    require "DataProvider/$provider_class.pm";
                    my $comp =  $set->indicatorset_component ? $args{'components'}->{ $set->indicatorset_component } : undef;
                    my $provider_class_prefixed = 'DataProvider::'.$provider_class;
                    $data_provider = $provider_class_prefixed->new(
                        host      => $host,
                        component => $comp
                    );
                    $providers{$provider_class} = $data_provider;
                }

                ############################################################################################################
                # Retrieve the map ref { index => { var_name => value } } corresponding to required var_map for each entry #
                ############################################################################################################
                my $retrieve_set_start_time = time();
                if ( defined $set->indicatorset_tableoid ) {
                    ($time, $update_values) = $data_provider->retrieveTableData(
                                                  table_oid => $set->indicatorset_tableoid,
                                                  index_oid => $set->indicatorset_indexoid,
                                                  var_map => \%var_map
                                              );
                } else {
                    ($time, $update_values->{"0"}) = $data_provider->retrieveData(
                                                         var_map => \%var_map,
                                                     );
                    if ($data_provider->isDiscrete()) {
                        my $mod_time = $time % $self->{config}->{time_step};
                        $time += ($mod_time > $self->{config}->{time_step} / 2) ? $self->{config}->{time_step} - $mod_time : -$mod_time;
                    }
                }

                $retrieve_set_time = time() - $retrieve_set_start_time;
            };
            if ($@) {
                #####################
                # Handle exceptions #
                #####################
                my $error = $@;
                $log->warn( "[$host_name] Collecting data set '" . $set->indicatorset_name . "' => $provider_class : $error" );
                #TODO find a better way to detect unreachable host (grep error string is not very safe)
                if ( "$error" =~ "No response" || "$error" =~ "Can't connect") {
                    $provider_class =~ /(.*)Provider/;
                    my $comp = $1;
                    my $mess = "Can not reach component '$comp' on $host_name ($host_ip)";
                    if ( $host->host_state =~ "up" ) {
                        $log->info( "Unreachable host '$host_name' (IP $host_ip, component '$comp') => we stop collecting data.");
                        Message->send(from => 'Monitor', level => "warning", content => $mess );
                    }
                    $host_reachable = 0;
                    last SET; # we stop collecting data sets
                } else {
                    my $mess = "[$host_name] Error while collecting data set '" . $set->indicatorset_name . "' => $error";
                    $log->warn($mess);
                    Message->send(from => 'Monitor', level => "warning", content => $mess );
                    $error_happened = 1;
                }
                next SET; # continue collecting the other data sets
            }

            #############################################
            # Store new values in the corresponding RRD #
            #############################################
            # we loop because updates_values can be rows of table
            while ( my ($index, $values) = each %$update_values) { 
                # Log value of indicators
                $log->debug("[$host_name](" . $retrieve_set_time . "s) '" . $set->indicatorset_name . "' => "
                             . join( " | ", map { "$_" . ($index eq "0" ? "" : ".$index") . ":$values->{$_}" } keys %$values ));
                
                my $set_name = $set->indicatorset_name . ( $index eq "0" ? "" : ".$index" );
                my $rrd_name = Retriever->rrdName(set_name => $set_name, host_name => $host_name);
                my %stored_values = $self->updateRRD(
                                        rrd_name => $rrd_name,
                                        set_name => $set_name,
                                        ds_type  => $set->indicatorset_type,
                                        time     => $time,
                                        data     => $values
                                    );
                
                $all_values{ $set_name } = \%stored_values;
            }
        }
    };
    if ($@) {
        $error = $@;
        $log->error( $error );
        $error_happened = 1;
        #TODO manage $host_state in this case (error)
    }
    
    $log->warn("[$host_name] => some errors happened collecting data " . $error) if ($error_happened);
    $log->info("[$host_name] Collect time : " . (time() - $start_time));
    
    return \%all_values;
}


=pod
=begin classdoc

Store current node count of each state ('up', 'down',...) for a cluster

@param cluster_name

@param nodes_state array ref of states

=end classdoc
=cut

sub updateClusterNodeCount {
    my $self = shift;
    my %args = @_;

    my ($cluster_name, $nodes_state) = ($args{cluster_name}, $args{nodes_state});

    # RRD for node count
    my $rrd_file = "$self->{config}->{rrd_base_directory}/nodes_$cluster_name.rrd";
    my $rrd = RRDTool::OO->new( file =>  $rrd_file );
    if ( not -e $rrd_file ) {
        $log->info("Info: create nodes rrd for '$cluster_name'");
        $rrd->create(step    => $self->{config}->{time_step},
                     archive => { rows => $self->{config}->{storage_duration} / $self->{config}->{time_step} },
                     archive => {
                         rows => $self->{config}->{storage_duration} / $self->{config}->{time_step},
                         cpoints => 10,
                         cfunc => "AVERAGE"
                     },
                     data_source => { name => 'up', type => 'GAUGE' },
                     data_source => { name => 'starting', type => 'GAUGE' },
                     data_source => { name => 'stopping', type => 'GAUGE' },
                     data_source => { name => 'broken', type => 'GAUGE' });
    }
    
    my %count;
    
    # Nodes
    $count{up} = scalar grep { $_ =~ '^in' } @$nodes_state;
    $count{starting} = scalar grep { $_ =~ 'goingin' } @$nodes_state;
    $count{stopping} = scalar grep { $_ =~ 'goingout' } @$nodes_state;
    $count{broken} = scalar grep { $_ =~ 'broken' } @$nodes_state;

    # we want update the rrd at time multiple of time_step (to avoid rrd extrapolation)
    my $time = time();
    my $mod_time = $time % $self->{config}->{time_step};
    $time += ($mod_time > $self->{config}->{time_step} / 2) ? $self->{config}->{time_step} - $mod_time : -$mod_time; 
    eval {
        $rrd->update( time => $time, values => \%count );
    };
    if ($@) {
        my $error = $@;
        if ($error =~ "illegal attempt to update using time") {
            $log->warn("=> same nodecount update time.");
        }
        else {
            die $error;
        }
    }
}


=pod
=begin classdoc

Aggregate and store indicators values for each set for a cluster

@param cluster Entity::ServiceProvider::Cluster

@param hosts_values hash ref : indicators values of each set for each hosts

@param collect_time seconds since Epoch when hosts data have been collected 

=end classdoc
=cut

sub updateClusterData {
    my $self = shift;
    my %args = @_;

    my ($cluster, $hosts_values, $collect_time ) = ($args{cluster}, $args{hosts_values}, $args{collect_time});
    my $cluster_name = $cluster->getAttr( name => "cluster_name" );
    
    my @mbs = $cluster->getHosts();
    my @in_node_mb = grep { $_->getNodeState() =~ '^in' } @mbs; 
    
    # No more aggregating cluster values here since it's handled by cluster metrics mecanism (aggregator)
    # Update: we still aggregate values for billing purpose (TODO use aggregate clustermetric for billing)
    # TODO clean
    my $aggregate = 1;
    if ( $aggregate ) {
        # Group indicators values by set
        my %sets;
        foreach my $mb (@in_node_mb) {
            my $host_name = $mb->node->node_hostname;
            my @sets_name = keys %{ $hosts_values->{ $host_name } };
            foreach my $set_name ( @sets_name ) {
                push @{$sets{$set_name}}, $hosts_values->{ $host_name }{$set_name};
            }
        }

        # For each sets, aggregate values and store
        SET:
        while ( my ($set_name, $sets_list) = each %sets ) {
            if ( scalar @in_node_mb != scalar @$sets_list ) {
                $log->warn("During aggregation => missing set '$set_name' for one node of cluster '$cluster_name'. Cluster aggregated values for this set as considered undef.");
                next SET;
            }

            my %aggreg_mean = $self->aggregate( hash_list => $sets_list, f => 'mean' );
            my %aggreg_sum = $self->aggregate( hash_list => $sets_list, f => 'sum' );

            next SET if ( scalar grep { not defined $_ } values %aggreg_sum );

            my $base_rrd_name = Retriever->rrdName(set_name => $set_name, host_name => $cluster_name);
            my $mean_rrd_name = $base_rrd_name . "_avg";
            my $sum_rrd_name = $base_rrd_name . "_total";

            eval {
                $self->updateRRD(rrd_name => $mean_rrd_name,
                                 set_name => $set_name,
                                 ds_type => 'GAUGE',
                                 time => $collect_time,
                                 data => \%aggreg_mean);

                $self->updateRRD(rrd_name => $sum_rrd_name,
                                 set_name => $set_name,
                                 ds_type  => 'GAUGE',
                                 time     => $collect_time,
                                 data     => \%aggreg_sum);
            };
            if ($@){
                my $error = $@;
                $log->error("Update cluster rrd error => $error");
            }
        }
    }

    # log cluster nodes state
    my @state_log = map { $_->node->node_hostname . " (" .
                          $_->host_state . ", node:" .  $_->getNodeState() . ")"
                        } @mbs;

    $log->debug( "# '$cluster_name' nodes : " . join " | ", @state_log );
    
    # update cluster node count
    my @hosts_state = map { $_->getState() } @mbs;
    my @nodes_state = map { $_->getNodeState() } @mbs;

    $self->updateClusterNodeCount(
        cluster_name => $cluster_name,
        nodes_state  => \@nodes_state,
        hosts_state  => \@hosts_state
    );
}


=pod
=begin classdoc

Update data for every monitored host and then update clusters data

=end classdoc
=cut

sub update {
    my $self = shift;
    
    # Flag to switch between threaded mode or not.
    # Threaded mode: allow to manage simultaneously each host and so speed up the entire update
    #                 but some memory leaks happen and collector can seg fault (TODO make it work properly)
    my $THREADED = 0;
    
    my $start_time = time();
    
    eval {
        my %hosts_values = ();
        my @clusters = Entity::ServiceProvider::Cluster->search(hash => {}, expand => ['nodes']);

        foreach my $cluster (@clusters) {
            $log->info("Update nodes data of cluster " . $cluster->cluster_name);

            # Get components of this cluster
            my @components = $cluster->getComponents(category => 'all');
            my %components_by_name = map { $_->component_type->component_name => $_ } @components;

            # Get set to monitor for this cluster
            my @monitored_sets = Indicatorset->search(hash => { 'collects.service_provider_id' => $cluster->id });
            my @db_monitored_sets  = ();
            my @net_monitored_sets = ();

            for my $monitor_set (@monitored_sets) {
                if ($monitor_set->indicatorset_provider eq 'KanopyaDatabaseProvider') {
                    push @db_monitored_sets, $monitor_set;
                }
                else {
                    push @net_monitored_sets, $monitor_set;
                }
            }

            # Collect data for nodes in the cluster
            foreach my $node ($cluster->nodes) {
                my $host = $node->host;

                # Collect KanopyaDB anyway
                my %params = (
                    host       => $host,
                    components => \%components_by_name,
                    sets       => \@db_monitored_sets,
                );
                my $db_data = $self->updateHostData( %params );

                # Collect rest of sets only if node is up
                my $net_data;
                if ($node->node_state =~ '^in') {
                    $params{sets} = \@net_monitored_sets;
                    $net_data = $self->updateHostData( %params );
                }
                $hosts_values{ $host->node->node_hostname } = Hash::Merge::merge($db_data, $net_data);
            }
        }

        #################################################################
        # update clusters databases (nodes count and aggregated values) #
        #################################################################
        foreach my $cluster (@clusters) {
            $self->updateClusterData(
                cluster      => $cluster,
                hosts_values => \%hosts_values,
                collect_time => $start_time,
            );
        }
        
        # Update total consumption
        $self->updateConsumption();
    };
    if ($@) {
        my $error = $@;
        $log->error( $error );
        if ($error->can('trace')) {
            $log->error( $error->trace->as_string );
        }
    }
}


=pod
=begin classdoc

update Consumption

=end classdoc
=cut

sub updateConsumption {
    my $self = shift;
    
    # RRD for microcluster consumption
    my $rrd_file = "$self->{config}->{rrd_base_directory}/total_consumption.rrd";
    my $rrd = RRDTool::OO->new( file =>  $rrd_file );
    if ( not -e $rrd_file ) {    
        $log->info("Info: create total consumption rrd");
        $rrd->create(
            step    => $self->{config}->{time_step},
            archive => {
                rows => $self->{config}->{storage_duration} / $self->{config}->{time_step}
            },
            archive => {
                rows    => $self->{config}->{storage_duration} / $self->{config}->{time_step},
                cpoints => 10,
                cfunc   => "AVERAGE"
            },
            data_source => {
                name => 'consumption',
                type => 'GAUGE'
            },
        );
    }

    my $consumption = 0;
    my @up_hosts = Entity::Host->search(hash => { host_state => { -like => 'up:%' } });
    for (@up_hosts) {
        my %model = $_->getModel();
        $consumption += $model{hostmodel_consumption} || 0;
    }
    
    $rrd->update(time   => time(),
                 values => { 'consumption' => $consumption } );
}

1;

