package KanopyaUI::Orchestration;
use base 'KanopyaUI::CGI';

use Data::Dumper;
use Log::Log4perl "get_logger";
use XML::Simple;
use JSON;
		
my $log = get_logger("administrator");

sub getOrchestratorConf () {
	my $self = shift;
	
	my $conf = XMLin("/opt/kanopya/conf/orchestrator.conf");

	return $conf;
}

=head2 save_orchestrator_settings
	
	Class : Public
	
	Desc : 	Called by client to save monitoring settings.
			Transform: query params (json) -> perl type (according to xml conf struct) -> xml (conf) 
	
=cut

sub save_orchestrator_settings : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	
	my $cluster_id = $query->param('cluster_id') || 0;
	my $rules_str = $query->param('rules'); # stringified array of hash
	my $rules = decode_json $rules_str;
	
	my $optim_str = $query->param('optim_conditions'); # stringified array of hash
	my $optim_cond = decode_json $optim_str;
		
	#return Dumper $rules;
	
	my $rules_manager = $self->{'adm'}->{manager}->{rules};
	eval {
		$rules_manager->deleteClusterRules( cluster_id => $cluster_id );
		foreach my $rule (@$rules) {
			$rules_manager->addClusterRule( cluster_id => $cluster_id,
	                                		condition_tree => (ref $rule->{condition} eq 'ARRAY') ? $rule->{condition} : [$rule->{condition}],
	                                		action => $self->actionTranslate( action => $rule->{action} )
	                                		);
		}
		
		$rules_manager->deleteClusterOptimConditions( cluster_id => $cluster_id );
		$rules_manager->addClusterOptimConditions( cluster_id => $cluster_id, condition_tree => $optim_cond );
	};
	if ($@) {
		my $error = $@;
		return "Error while recording rule for cluster $cluster_id\n$error";
	}
	
	return "Rules saved for cluster $cluster_id ";
}

sub actionTranslate {
	my $self = shift;
	my %args = @_;
	
	my %map = ("add_node" => "Add node", "remove_node" => "Remove node");
	while ( my ($k, $v) = each ( %map ) ) {
		return $v if $k eq $args{action};
		return $k if $v eq $args{action};
	}
	return "none";
}

sub view_orchestrator_settings : StartRunmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	my $tmpl = $self->load_tmpl('Orchestrator/view_orchestrator_settings.tmpl');
	
	my $cluster_id = $query->param('cluster_id') || 0;

	# Build var choice list of all collected set
	my $sets = $self->{adm}->{manager}{monitor}->getCollectedSets( cluster_id => $cluster_id );
	my @choices = ();
	foreach my $set (@$sets) {
		push( @choices, map { "$set->{label}:" . $_->{label} } @{ $set->{ds} } );
	}
	my $var_choices = join ",", @choices;
	
	my @rules = ();
	my $rules_manager = $self->{'adm'}->{manager}->{rules};
	my $cluster_rules = $rules_manager->getClusterRules( cluster_id => $cluster_id );
	my $op_id = 0;
	foreach my $rule (@$cluster_rules) {
		my $condition_tree = $rule->{condition_tree};

		my @conditions = ();
		$op_id++;
		my $bin_op;
		foreach my $cond (@$condition_tree) {
			if ( ref $cond eq 'HASH' ) {
				push @conditions, { var => $cond->{var},
									time_laps => $cond->{time_laps},
									inf => $cond->{operator} eq 'inf',
									value => $cond->{value},
									var_choices => $var_choices,					
									op_id => $op_id,
								};
			} else {
				$bin_op = {'|' => 'or', '&' => 'and'}->{$cond};
			}
		}
		
		$conditions[0]{master_row} = 1;
		$conditions[0]{bin_op} = $bin_op if (defined $bin_op);
		$conditions[0]{action} = $self->actionTranslate( action => $rule->{action} );
		$conditions[0]{span} = scalar @conditions;
		
		push @rules, { conditions => \@conditions };
	}
		
	
	my @optim_conditions = ();
	my $optim_condition_tree = $rules_manager->getClusterOptimConditions( cluster_id => $cluster_id );
	foreach my $cond (@$optim_condition_tree) {
			if ( ref $cond eq 'HASH' ) {
				push @optim_conditions, { var => $cond->{var},
									time_laps => $cond->{time_laps},
									inf => $cond->{operator} eq 'inf',
									value => $cond->{value},
									var_choices => $var_choices,					
									op_id => 0,
								};
			} else {
				#$bin_op = {'|' => 'or', '&' => 'and'}->{$cond};
			}
		}
	
	$tmpl->param('OPTIM_CONDITIONS' => \@optim_conditions);
	
	$tmpl->param('RULES' => \@rules);
	$tmpl->param('VAR_CHOICES' => $var_choices);
	$tmpl->param('TITLEPAGE' => "Orchestrator settings");
	$tmpl->param('MSETTINGS' => 1);
	$tmpl->param('SUBMORCHESTRATOR' => 1);
	
	return $tmpl->output();
}


1;
