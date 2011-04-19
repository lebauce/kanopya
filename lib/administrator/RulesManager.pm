# RulesManager.pm - Object class of Rules Manager included in Administrator

# Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

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
# Created 2 december 2010
package RulesManager;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use McsExceptions;
use Parse::BooleanLogic;

my $log = get_logger("administrator");
my $errmsg;

=head2 RulesManager::new (%args)
	
	Class : Public
	
	Desc : Instanciate Rules Manager object
	
	args: 
		shemas : DBIx:Schema : Database schemas

	return: RulesManager instance
	
=cut

sub new {
	my $class = shift;
	my %args = @_;
	my $self = {};
	if (! exists $args{schemas} or ! defined $args{schemas}){
		$errmsg = "RulesManager->new needz schemas named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal(error => $errmsg);
	}
	$self->{db} = $args{schemas};
	
	$self->{parser} = Parse::BooleanLogic->new( operators => [qw(& |)] );
	
	bless $self, $class;
	$log->info("New Rules Manager Loaded");
	return $self;
}

=head2 addClusterRule
	
	Class : Public
	
	Desc :
	
	Args :
		condition_tree: [ COND, OP, COND, ... ]
			with	COND: 	a condition tree [ COND, ..] 
							or a condition leaf { var => '',  }
					OP: '|' or '&'
		action: string: associated action
		cluster_id: int
		
	Return :
	
=cut

sub addClusterRule {
	my $self = shift;
	my %args = @_;

	# try to create rule
	eval {
		my $row = { cluster_id => $args{cluster_id}, rule_action => $args{action} };
		my $new_rule = $self->{db}->resultset('Rule')->create($row);
		
		# Parse condition tree: add conditions in db and create rule condition string
		my $cond_str = '';
		$self->{parser}->walk(
		        $args{condition_tree},
		        {
		            open_paren => sub { $cond_str .= '('; },
		            close_paren => sub { $cond_str .= ')'; },
		            operator => sub { my $op = shift; $cond_str .= $op; },
		            operand => sub { 
		            	my $op = shift;
		            	my %row = ();
		            	while (my ($op_key, $op_val) = each %$op) {
		            		$row{ 'rulecondition_' . $op_key } = $op_val;
		            	}
		            	my $res = $new_rule->create_related('ruleconditions', \%row);
		            	my $cond_id = $res->get_column('rulecondition_id');
		            	$cond_str .= $cond_id;
		            },
		        },                                                                                                                   
	    );

		$new_rule->set_column( 'rule_condition', $cond_str);
		$new_rule->update();
		
	};
	if($@) { 
		$errmsg = "RulesManager->addClusterRule: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
	$log->debug("new rule added for cluster " . $args{cluster_id} );	
	
}

=head2 deleteClusterRules
	
	Class : Public
	
	Args: cluster_id: int
		  (optional) action: get only rules with this action
		  
	Desc : delete all rules for cluster
	
	Args : cluster_id: int
	
=cut

sub deleteClusterRules {
	my $self = shift;
	my %args = @_;
	
	my %search = ( cluster_id => $args{cluster_id} );
	$search{rule_action} = ( defined $args{action} ) ? $args{action} : { 'not in' => "optim" };
	
	my $rules = $self->{db}->resultset('Rule')->search( \%search );
	$rules->delete;
	
	$log->debug("Rules deleted for cluster " . $args{cluster_id} );	
}

=head getClusterRules

	Args: cluster_id: int
		  (optional) action: get only rules with this action
	
	return list of rules for cluster

=cut

sub getClusterRules {
	my $self = shift;
	my %args = @_;
	
	my %search = ( cluster_id => $args{cluster_id} );
	$search{rule_action} = ( defined $args{action} ) ? $args{action} : { 'not in' => "optim" };
	
	my $rules = $self->{db}->resultset('Rule')->search( \%search );
	my $condition_rs = $self->{db}->resultset('Rulecondition');
	
	my $rules_array = [];
	while(my $r = $rules->next) {
		my ($condition_str, $action) = ($r->get_column('rule_condition'), $r->get_column('rule_action'));
		
		my $tree = $self->{parser}->as_array( $condition_str,
     		operand_cb => sub {
	            my $cond_id = shift;
	            my $cond_row = $condition_rs->find( $cond_id );
	            if (not defined $cond_row ) {
	            	$log->error("Rule condition doesn't exist: rule id: " . $r->get_column('rule_id') . " cond id: " . $cond_id );
	            	return 0;
	            }
	            my @cond = map { $_ => $cond_row->get_column('rulecondition_' . $_) } ('var', 'value', 'operator', 'time_laps');
	            my %cond = @cond;
	            return \%cond;
	        },
        );
		
		push @$rules_array, { condition_tree => $tree, action => $action };
	}
	
	return $rules_array;
}

sub getClusterOptimConditions {
	my $self = shift;
	my %args = @_;
	
	my $optim_rule = $self->getClusterRules( cluster_id => $args{cluster_id}, action => "optim" );
	
	if ( $optim_rule->[0] ) {
		return $optim_rule->[0]{condition_tree};
	}
	return [];
}

sub addClusterOptimConditions {
	my $self = shift;
	my %args = @_;
	
	$self->addClusterRule( cluster_id => $args{cluster_id}, condition_tree => $args{condition_tree}, action => "optim" );	
}

sub deleteClusterOptimConditions {
	my $self = shift;
	my %args = @_;
	
	$self->deleteClusterRules( cluster_id => $args{cluster_id}, action => "optim" );
}

=head2 getClusterModelParameters
	
	Class : Public
	
	Desc : retrieve from db parameters used by cluster model, (workload type specification) 
	
	Args : cluster id
	
	Return : model parameters
	
=cut

#TODO move in Cluster class
sub getClusterModelParameters {
	my $self = shift;
	my %args = @_;
	
	return {	visit_ratio => 1,
				service_time => 0.002,
				delay => 0,
				think_time => 0.01 };
}

sub setClusterModelParameters {
	my $self = shift;
	my %args = @_;
	
	my $row = { cluster_id => $args{cluster_id},
				wc_visit_ratio => $args{visit_ratio},
				wc_service_time => $args{service_time},
				wc_delay => $args{delay},
				wc_think_time => $args{think_time},
				 };
	
	eval {			 
		$self->{db}->resultset('WorloadCharacteristic')->create($row);
	};
	if($@) { 
		$errmsg = "RulesManager->setClusterModelParameters: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
}

sub getClusterQoSConstraints {
	my $self = shift;
	my %args = @_;
	
	return { max_latency => 22, max_abort_rate => 0.3 } ;
}

sub setClusterQoSConstraints {
	my $self = shift;
	my %args = @_;
	
	my $row = { cluster_id => $args{cluster_id},
				constraint_max_latency => $args{max_latency},
				constraint_max_abort_rate => $args{abort_rate},
			};
	
	eval {			 
		$self->{db}->resultset('QosConstraint')->create($row);
	};
	if($@) { 
		$errmsg = "RulesManager->setClusterQoSConstraints: $@";
		$log->error($errmsg);
		throw Mcs::Exception::DB(error => $errmsg);
	}
}

1;