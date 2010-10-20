# Orchestrator.pm - Object class of Orchestrator

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 1 september 2010

=head1 NAME

Orchestrator - Orchestrator object

=head1 SYNOPSIS

    use Orchestrator;
    
    # Creates orchestrator
    my $orchestrator = Orchestrator->new();

=head1 DESCRIPTION

Orchestrator is the main object for mc management politic. 

=head1 METHODS

=cut

package Orchestrator;

###############################################################################################################
#TODO Remove node from cluster
#		- Le cluster doit vérifier l'ensemble des conditions spécifiées
#				=> 2 types possibles de conditions:
#						- seuil sur valeur
#						- seuil de performance voulu après le retrait du noeud (permet de supprimer des noeud plus rapidemment sans attendre un seuil bas)						
#		- Il n'y a pas eu d'ajout d'un noeud dans le cluster depuis un certain laps de temps (conf)


#TODO vérifier que le retrait d'un noeud a un impact direct sur les valeurs remontées (à l'inverse de l'ajout d'un noeud)
#TODO 	les moyennes remontées par le monitor sont calculées par rapport à l'ensemble des nodes 'up' (logique)
#		On pourrait prendre en compte les nodes 'starting' ce qui fausserais les moyennes courantes mais nous donnerais une idée de la charge une fois le noeud 'up' (prévision) (?)
    
#WARN l'orchestrator considère actuellement que les noeuds sont homogènes et ne prend pas en compte les spécificités de chaque carte
#TODO Prendre en compte les spécificités des cartes dans les algos, faire un système de notation pour le choix des cartes à ajouter/supprimer
#TODO Percent option. WARN: avg % != % avg

#TODO log
#TODO use mcs exception
###############################################################################################################
 

use lib qw(/workspace/mcs/Monitor/Lib);

use strict;
use warnings;
use Monitor::Retriever;
use XML::Simple;
use General;
use AdminWrapper;

use Data::Dumper;

				
=head2 new
	
	Class : Public
	
	Desc : Instanciate Orchestrator object
	
	Return : Orchestrator instance
	
=cut

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	# Load conf
	my $conf = XMLin("/workspace/mcs/Orchestrator/Conf/orchestrator.conf");
	$self->{_time_step} = $conf->{time_step};
	$self->{_traps} = General::getAsArrayRef( data => $conf->{add_rules}, tag => 'traps' );
	$self->{_conditions} = General::getAsArrayRef( data => $conf->{delete_rules}, tag => 'conditions' );
	
	$self->{_rrd_base_dir} = $conf->{rrd_base_dir} || '/tmp/orchestrator';
	$self->{_graph_dir} = $conf->{graph_dir} || '/tmp/orchestrator';
	
	# Create orchestrator dirs if needed
	for my $dir_path ( ($self->{_graph_dir}, $self->{_rrd_base_dir}) ) { 
		my @dir_path = split '/', $dir_path;
		my $dir = substr($dir_path, 0, 1) eq '/' ? "/" : "";
		while (scalar @dir_path) {
			$dir .= (shift @dir_path) . "/";
			mkdir $dir;
		}
	}
	
	# Get Administrator
	#$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );
	$self->{_admin_wrap} = AdminWrapper->new( );
	$self->{_monitor} = Monitor::Retriever->new( );
	
    return $self;
}

=head2 manage
	
	Class : Public
	
	Desc : 	Check mc state and manage clusters.
			For each cluster, detect traps (for adding node) and check conditions for removing node
	
=cut

sub manage {
	my $self = shift;
	
	print "Manage\n";
	
	my $monitor = $self->{_monitor};
	
	my @all_clusters_name = $monitor->getClustersName();
	for my $cluster (@all_clusters_name) {
		print "# CLUSTER: $cluster\n";
	
		##########################################################################################################
		#TODO on peut tester ici si il est cohérent de faire les tests (traps et conditions) pour ce cluster
		#				-> pas de node starting ou stopping dans le cluster
		#				-> pas d'operation add ou remove dans la queue
		#				-> au moins 2 noeuds pour les tests de remove
		#				-> nombre de noeuds constant depuis un certain temps (conf)
		# ceci afin d'éviter de faire les récupérations de données et les calculs
		# Mais du coup on aura pas les infos en continue à stocker et grapher sur les différentes valeurs
		# Pas forcément très grave, on peut stocker une variable spéciale précisant que l'on pas fait les tests puisque non nécessaire  
		##########################################################################################################
	
		eval {
			# Detect trap for adding node
			my $cluster_trapped = $self->detectTraps( cluster_name => $cluster );
			
			# Check conditions for remove node
			$self->checkRemoveConditions( cluster_name => $cluster ) if (not $cluster_trapped);
			
			# Update graph for this cluster
			$self->updateGraph( cluster => $cluster );
		};
		if ($@) {
			my $error = $@;
			print "error for cluster '$cluster' : $error\n";
		}
	}
	
}

sub updateGraph {
	my $self = shift;
	my %args = @_;
	my $cluster = $args{cluster};
	$self->graph( cluster => $cluster, op => 'add' );
	$self->graph( cluster => $cluster, op => 'remove' );
}

sub checkRemoveConditions {
	my $self = shift;
	my %args = @_;
	
	my $cluster = $args{cluster_name};
	my $monitor = $self->{_monitor};
	
	my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster );
	my $upnode_count = grep { $_->{state} =~ 'up' } values %$cluster_info;
	
	if ( $upnode_count <= 1 ) {
		print "No node to eventually remove => don't check remove conditions\n";
		return;
	}
	
	#TODO vérifier que le nombre de noeud est constant depuis un certains temps (sinon ça fausse les moyennes? à vérifier)
	#	=> point critique! à tester en profondeur 
	
	#TODO si il y a un node starting/broken alors return ? sauf si on l'a déjà testé en amont
	
	my $required_failed = 0;
	my $one_required_ok = 0;
	my %values = ();
	for my $cond ( @{ $self->{_conditions} } ) {
		print "	# CONDITIONS on '$cond->{set}' (laps: $cond->{time_laps})\n";
		my $cluster_data_aggreg;
		eval {
			$cluster_data_aggreg = $monitor->getClusterData( 	cluster => $cluster,
																set => $cond->{set},
																time_laps => $cond->{time_laps},
																percent => $cond->{percent},
																aggregate => "mean");
		};
		if ($@) {
			my $error = $@;
			print "=> Error getting data (set '$cond->{set}' for cluster '$cluster') : $error\n";
			next;
		}
		
		foreach my $required ( @{ General::getAsArrayRef( data => $cond, tag => 'required' ) }) {
			
			my $value = $cluster_data_aggreg->{ $required->{var} };
			if (not defined $value) {
				print "Warning: no value for var '$required->{var}' in cluster '$cluster'. required ignored.\n";
				next;
			}
			
			###################################################################
			# Compute prevision for this value if we remove a node
			# Based on mean value so we consider all nodes have the same current load
			#TODO is it good ? 
			###################################################################
			my $prevision = $value + ( $value / ( $upnode_count - 1 ));
			
			$values{ $required->{var} . "_" . $cond->{time_laps} } = $prevision;
			
			print "				=> REQUIRED : ($required->{var} current = $value prevision = $prevision ", defined $required->{max}?" max : $required->{max}":" min : $required->{min}" ," )\n";
			
			if ( 	( defined $required->{max} && $prevision < $required->{max} )
				|| 	( defined $required->{min} && $prevision > $required->{min} ) ) {
				print "				======> REQUIRED ok\n";
				$one_required_ok = 1;
			} else {
				print "				======> REQUIRED failed\n";
				$required_failed = 1;
			}
			
		} # end required
	} # end conditions
	
	# Store values
	if ( scalar keys %values ) {
		$self->updateRRD( cluster => $cluster, op => 'remove', time => time(), values => \%values  )
	}
	
	# Required remove node if all conditions are ok
	if ( $required_failed == 0 && $one_required_ok != 0 ) {
		print "========> REQUIRED REMOVE NODE : $required_failed | $one_required_ok\n\n";
		$self->requireRemoveNode( cluster => $cluster );
	}
	
}

sub detectTraps {
	my $self = shift;
	my %args = @_;
	
	my $cluster = $args{cluster_name};
	my $monitor = $self->{_monitor};
	
	my %values = ();
	my $cluster_trapped = 0;
	for my $trap_def ( @{ $self->{_traps} } ) {
#		if ($cluster_trapped) {
#			print " ==> skip\n";
#			last;
#		}
		print "	# TRAPS on '$trap_def->{set}' (laps: $trap_def->{time_laps})\n";
		my $cluster_data_aggreg;
		eval {
			$cluster_data_aggreg = $monitor->getClusterData( 	cluster => $cluster,
																set => $trap_def->{set},
																time_laps => $trap_def->{time_laps},
																percent => $trap_def->{percent},
																aggregate => "mean");
		};
		if ($@) {
			my $error = $@;
			print "=> Error getting data (set '$trap_def->{set}' for cluster '$cluster') : $error\n";
			next;
		}
		foreach my $threshold ( @{ General::getAsArrayRef( data => $trap_def, tag => 'threshold' ) }) {
			
			my $value = $cluster_data_aggreg->{ $threshold->{var} };
			if (not defined $value) {
				print "Warning: no value for var '$threshold->{var}' in cluster '$cluster'. Trap ignored.\n";
				next;
			}
			
			$values{  $threshold->{var} . "_" . $trap_def->{time_laps} } = $value;
			
			print "		# THRESHOLD  : $threshold->{var} ", defined $threshold->{max}?"max=$threshold->{max}":"min=$threshold->{min}", " value=$value\n";
			if ( 	( defined $threshold->{max} && $value > $threshold->{max} )
				|| 	( defined $threshold->{min} && $value < $threshold->{min} ) ) {
				print "				======> TRAP!  ($cluster: $threshold->{var} = $value ", defined $threshold->{max}?"> $threshold->{max}":"< $threshold->{min}" ," )\n";
				$cluster_trapped = 1;
				#last;		
			}
		} # end threshold
	} #end traps
	
	# Store values
	if ( scalar keys %values ) {
		$self->updateRRD( cluster => $cluster, op => 'add', time => time(), values => \%values  )
	}

	# Require add if trapped
	if ( $cluster_trapped ) {
		$self->requireAddNode( cluster => $cluster );
	}
				
	return $cluster_trapped;
}

=head2 _isNodeInState
	
	Class : Private
	
	Desc : Check if there is a least one node in the specificied state in the cluster
	
	Args :
		cluster: name of the cluster
		state: state name
	
	Return :
		0 : not found
		1 : there is a node with this state in the cluster  
	
=cut

sub _isNodeInState {
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};	
    my $state = $args{state};
    
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster );
    foreach my $host (values %$cluster_info) {
    	if ($host->{state} =~ $state) {
    		return 1;
    	}
    }
    return 0;
}

=head2 _isOpInQueue
	
	Class : Private
	
	Desc : Check if there is an operation of the specified type associated to the cluster
	
	Args :
		cluster: name of the cluster
		type: operation type name (corresponding to operation class name)
	
	Return :
		0 : not found
		1 : there is a operation of this type for this cluster
	
=cut

sub _isOpInQueue {
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    my $type = $args{type};
    
	my $adm = $self->{_admin_wrap};
	
	my $cluster_id = $adm->getClusterId( cluster_name => $cluster );
	
	foreach my $op ( @{ $adm->getOperations() } ) {
    	if ($op->{'TYPE'} eq $type) {
    		foreach my $param ( @{ $op->{'PARAMETERS'} } ) {
    			if ( ($param->{'PARAMNAME'} eq 'cluster_id') && ($param->{'VAL'} eq $cluster_id) ) {
    				return 1;
    			}
    		}	
    	}
    }
    
    return 0;
}

=head2 _canAddNode
	
	Class : Private
	
	Desc : Check if all conditions to add a node in the cluster are met.
	
	Args :
		cluster : name of the cluster in which we want add a node
	
	Return :
		0 : one condition failed
		1 : ok 
	
=cut

sub _canAddNode {
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    # Check if there is already a node starting in the cluster #
    if ( $self->_isNodeInState( cluster => $cluster, state => 'starting' ) ) {
		print " => A node is already starting in cluster '$cluster'\n";
    	return 0;
    }
    
    # Check if there is a corresponding add node operation in operation queue #
    if ( $self->_isOpInQueue( cluster => $cluster, type => 'AddMotherboardInCluster' ) ) {
    	print " => An operation to add node in cluster '$cluster' is already in queue\n";
    	return 0;
    }
    
    return 1;
}

sub requireAddNode { 
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    print "Node required in cluster '$cluster'\n";
    
    # TEMP
    $self->_storeTime( time => time(), cluster => $cluster, op_type => "add", op_info => "req" );
    
    eval {
	   	if ( $self->_canAddNode( cluster => $cluster ) ) {
	    	$self->addNode( cluster_name => $cluster );
	    	$self->_storeTime( time => time(), cluster => $cluster, op_type => "add", op_info => "ok" );
	   	}
    };
    if ($@) {
		my $error = $@;
		print "=> Error while adding node in cluster '$cluster' : $error\n";
	}
}

=head2 _canRemoveNode
	
	Class : Private
	
	Desc : Check if all conditions to remove a node from the cluster are met.
	
	Args :
		cluster : name of the cluster in which we want remove a node
	
	Return :
		0 : one condition failed
		1 : ok 
	
=cut

sub _canRemoveNode {
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    # Check if there is a corresponding remove node operation in operation queue #
    if ( 	$self->_isOpInQueue( cluster => $cluster, type => 'RemoveMotherboardFromCluster' ) || 
    		$self->_isOpInQueue( cluster => $cluster, type => 'StopNode' ) )
    {
    	print " => An operation to remove node from cluster '$cluster' is already in queue\n";
    	return 0;
    }
    
    return 1;
}

sub requireRemoveNode { 
	my $self = shift;
    my %args = @_;
    
    my $cluster = $args{cluster};
    
    print "Want remove node in cluster '$cluster'\n";
    
   	# TEMP
    $self->_storeTime( time => time(), cluster => $cluster, op_type => "remove", op_info => "req");
    
    eval {
	   	if ( $self->_canRemoveNode( cluster => $cluster ) ) {
	    	$self->removeNode( cluster_name => $cluster );
	    	$self->_storeTime( time => time(), cluster => $cluster, op_type => "remove", op_info => "ok");
	   	}
    };
   	if ($@) {
		my $error = $@;
		print "=> Error while removing node in cluster '$cluster' : $error\n";
	}
    
}



sub addNode {
	my $self = shift;
    my %args = @_;
    
    print "====> add node in $args{cluster_name}\n";
       
    #my $adm = $args{adm};
    my $adm = $self->{_admin_wrap};
    
    my $priority = 1000;
    
	my @free_motherboards = $adm->getEntities(type => 'Motherboard', hash => { active => 1, motherboard_state => 'down'});
	
	die "No free motherboard to add in cluster '$args{cluster_name}'" if ( scalar @free_motherboards == 0 );
	
	#TODO  Select the best node ?
	my $motherboard = pop @free_motherboards;
	
 	my @cluster =  $adm->getEntities(type => 'Cluster', hash => { cluster_name => $args{cluster_name} } );
   	my $cluster = pop @cluster;
    
	############################################
	# Enqueue the add motherboard operation
	############################################
#	$adm->newOp(type => 'AddMotherboardInCluster',
#				priority => $priority,
#				params => {
#					cluster_id => $cluster->getAttr(name => "cluster_id"),
#					motherboard_id => $motherboard->getAttr(name => 'motherboard_id')
#				}
#	);
	$adm->opAdd( cluster => $cluster, motherboard => $motherboard, priority => $priority );

}

sub removeNode {
	my $self = shift;
    my %args = @_;
    
    print "====> remove node from $args{cluster_name}\n";
    
    my $priority = 1000;
    my $cluster_name = $args{cluster_name};
    
    my $adm = $self->{_admin_wrap};
    
    #TODO Find the best node to remove (notation system)
    my $monitor = $self->{_monitor};
    my $cluster_info = $monitor->getClusterHostsInfo( cluster => $cluster_name );
    my @up_nodes = grep { $_->{state} =~ 'up' } values %$cluster_info;
  
    my @cluster =  $adm->getEntities(type => 'Cluster', hash => { cluster_name => $cluster_name } );
    my $cluster = pop @cluster;
    my $master_node_ip = $adm->getClusterMasterNodeIp( cluster => $cluster );
    
    my $node_to_remove = shift @up_nodes;
    ($node_to_remove = shift @up_nodes) if ($node_to_remove->{ip} eq $master_node_ip);
    die "No up node to remove in cluster '$cluster_name'. This error should never happen!" if ( not defined $node_to_remove );
    my @mb =  $adm->getEntities(type => 'Motherboard', hash => { motherboard_internal_ip => $node_to_remove->{ip} } );
    my $mb_to_remove = pop @mb;
    die "Motherboard '$node_to_remove->{ip}' no more in DB. This error should never happen!" if ( not defined $mb_to_remove );

    
    ############################################
	# Enqueue the remove motherboard operation
	############################################
#	$adm->newOp(type => 'RemoveMotherboardFromCluster',
#				priority => $priority,
#				params => {
#					cluster_id => $cluster->getAttr(name => "cluster_id"),
#					motherboard_id => $mb_to_remove->getAttr(name => 'motherboard_id')
#				}
#	);
	$adm->opRemove( cluster => $cluster, motherboard => $mb_to_remove, priority => $priority );
}

=head2 _storeTime
	
	Class : Private
	
	Desc : 	Store in a file the date (in seconds) of an operation (add/remove node) on a cluster.
			Keep only the last $NUMBER_TO_KEEP values.
			Use _getTimes() to retrieve stored times.
	
	Args :
		time: time in second (since epoch) to store
		cluster: name of the cluster concerned by the operation
		op_type: operation type
	
=cut

sub _storeTime {
	my $self = shift;
    my %args = @_;
    
    my $NUMBER_TO_KEEP = 100;
    
    my $file = $self->_timeFile( cluster => $args{cluster} );  
    
    my $info = $args{op_info} || "";
    
    my $times = "";
    if ( open FILE, "<$file" ) {
	    $times = <FILE>;
	    close FILE;
    }
    my @times = $times ? split( /,/, $times ) : ();
    my @last_times = scalar @times > $NUMBER_TO_KEEP ? @times[$#times + 1 - $NUMBER_TO_KEEP .. $#times] : @times;
    push @last_times, "$args{op_type}:$info". '@' . "$args{time}";
    open FILE, ">$file";
    print FILE join(",", @last_times);
    close FILE;
}

=head2 _getTimes
	
	Class : Private
	
	Desc : Retrieve times corresponding to op_type for the cluster
	
	Args :
		cluster: name of the cluster concerned by the operation
		op_type: operation type
	
	Return : Array of times
	
=cut

sub _getTimes {
	my $self = shift;
    my %args = @_;

    my $file = $self->_timeFile( cluster => $args{cluster} );
    
    my %times = ();
   	if ( open FILE, "<$file" ) {
		my $times = <FILE>;
		close FILE;
		my @alltimes = split( /,/, $times );
		my @optimes = grep { $_ =~ $args{op_type} } @alltimes;
		foreach my $op ( @optimes ) {
			if ( $op =~ /[a-zA-Z_]+:([a-zA-Z_]*)@([\d]+)/ ) {
				$times{ $2 } = $1;
			}
		}
   	}
#   	else
#   	{
#   		print "Can't open orchestrator time file for cluster '$args{cluster}'\n";
#   	}
	
	return %times;
}

sub _timeFile  {
	my $self = shift;
    my %args = @_;

    return $self->{_rrd_base_dir} ."/" . "orchestrator" . "_" . "$args{cluster}" . ".time";
}

sub updateRRD {
	my $self = shift;
    my %args = @_;
    
    my $rrd = $self->getRRD( cluster => $args{cluster}, op => $args{op} );
	eval {
		$rrd->update( time => $args{time}, values => $args{values} );
	};
	if ($@) {
		my $error = $@;
		print "Info: conf changed ($error)\n";
		my $rrd = $self->getRRD( cluster => $args{cluster}, op => $args{op}, force_create => 1 );
		$rrd->update( time => $args{time}, values => $args{values} );
	}
}

sub getRRD {
	my $self = shift;
	my %args = @_;
	
	my $cluster = $args{cluster};
	my $rrd_file = "$self->{_rrd_base_dir}/orchestrator_$cluster" . "_$args{op}" . ".rrd";
	
	my $rrd;
	if ( -e $rrd_file && not defined $args{force_create} ) {
		$rrd = RRDTool::OO->new( file =>  $rrd_file );
	} else {
		print "info: create orchestrator rrd for cluster '$cluster'\n";
		$rrd = $self->createRRD( file => $rrd_file, op => $args{op} );
	}
	return $rrd;
}

sub createRRD {
	my $self = shift;
	my %args = @_;

	# Build list of var to store (all traps or conditions var)
	my ($rules, $tag) = $args{op} eq "add" ? ($self->{_traps}, 'threshold') : ($self->{_conditions}, 'required');
	
	my @var_list = ();
	for my $rule ( @{ $rules } ) {
		foreach my $cond ( @{ General::getAsArrayRef( data => $rule, tag => $tag ) }) {
			push @var_list, $cond->{var} . "_" . $rule->{time_laps};
		}
	}

	my $rrd = RRDTool::OO->new( file =>  $args{file} );

	#my $raws = $self->{_period} / $self->{_time_step};
	my $raws = 3000;

	my @rrd_params = ( 	'step', $self->{_time_step},
						'archive', { rows	=> $raws }
					 );
					 
	for my $name ( @var_list ) {
		push @rrd_params, 	(
								'data_source' => { 	name      => $name,
			     	         						type      => 'GAUGE' },			
							);
	}

	# Create a round-robin database
	$rrd->create( @rrd_params );
	
	return $rrd;
}


sub graph {
	my $self = shift;
	my %args = @_;

#    use Log::Log4perl qw(:easy);
#    Log::Log4perl->easy_init({
#        level    => $DEBUG
#    }); 
    
    my $cluster = $args{cluster};
    my $op = $args{op};
    
    my $time_laps = 3600;
    
    my $graph_dir = $self->{_graph_dir};
	my $graph_filename = "graph_orchestrator_$cluster" . "_$op" . ".png";

	#my ($set_def) = grep { $_->{label} eq $set_name} @{ $self->{_monitored_data} };
	#my $ds_list = General::getAsArrayRef( data => $set_def, tag => 'ds');

	my $rrd_file = "$self->{_rrd_base_dir}/orchestrator_$cluster" . "_$op" . ".rrd";

	return if ( not -e $rrd_file );

	# get rrd     
	my $rrd = RRDTool::OO->new( file => $rrd_file );

	my @graph_params = (
							'image' => "$graph_dir/$graph_filename",
							#'vertical_label', 'ticks',
							'start' => time() - $time_laps,
							color => { back => "#69B033" },
							
							title => ($args{op} eq "add" ? "Add" : "Remove") . " rules analysis",
							
							lower_limit => 0,
							#upper_limit => 100,
							
							#width => 500,
							#height => 500,

						);

	# Add vertical red lines corresponding to add times
	my %add_times = $self->_getTimes( cluster => $cluster, op_type => "add" );
	while ( my ($add_time, $add_info) = each %add_times ) {
		my $color = (defined $add_info && $add_info eq "ok") ? "#FF0000" : "#FFBBBB";
		push @graph_params, ( vrule => { time => $add_time, color => $color } );
	}

	# Add vertical green lines corresponding to remove times
	my %remove_times = $self->_getTimes( cluster => $cluster, op_type => "remove" );
	while ( my ($remove_time, $remove_info) = each %remove_times ) {
		my $color = (defined $remove_info && $remove_info eq "ok") ? "#00FF00" : "#BBFFBB";
		push @graph_params, ( vrule => { time => $remove_time, color => $color } );
	}
	
	# Graph data and add horizontal lines corresponding to thresholds for this op
	my ($rules, $tag) = $args{op} eq "add" ? ($self->{_traps}, 'threshold') : ($self->{_conditions}, 'required');
	my @var_list = ();
	for my $rule ( @{ $rules } ) {
		foreach my $cond ( @{ General::getAsArrayRef( data => $rule, tag => $tag ) }) {
			
			push @graph_params, (
									draw   => {
										type => 'line',
										dsname => $cond->{var} . "_" . $rule->{time_laps},
										color => $cond->{color},
										legend => sprintf( "%-25s", $cond->{var} .
																	( $args{op} eq "remove" ? " prevision" : "" ).
																	" (" . ($rule->{percent} ? "%" : "mean") .
																	" on " . $rule->{time_laps} . "s)" ),
		  							},
		  
		  							hrule => {
		  							 	value => $cond->{min} || $cond->{max},
                 						color => '#' . $cond->{color},
						                #legend => $cond->{var}
						               },
						              
								);
		}
	}

	# Draw the graph in a PNG image
	$rrd->graph( @graph_params );
	
	return "$graph_dir/$graph_filename";
}

# TEST
sub check {
	my %args = @_;
	
	my %check_args = %{ $args{args} };
	
	print "===> ", Dumper %check_args, "\n";
	print "===> @{$args{required}}\n";
	
	my $caller_sub = (caller(1))[3];
	print "$caller_sub\n";
	
	return 10;
}

# TEST
sub pouet {
	my $self = shift;
	my %args = @_;

	my ($p1, $p2) = check( args => \%args, required => ['p1', 'p2'] );

	print $p1;
	
	#my $p1 = $args{p1};
	
	
}

=head2 run
	
	Class : Public
	
	Desc : Do the job (check mc state and manage clusters) every time_step (configuration)
	
=cut

sub run {
	my $self = shift;

	while ( 1 ) {
		$self->manage();
		sleep( $self->{_time_step} );
	}
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut