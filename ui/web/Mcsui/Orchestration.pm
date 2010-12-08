package Mcsui::Orchestration;
use Data::Dumper;
use base 'CGI::Application';
use Log::Log4perl "get_logger";
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use XML::Simple;
use JSON;
		
my $log = get_logger("administrator");


sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}

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
	
	my $rules_str = $query->param('rules'); # stringified array of hash
	my $rules = decode_json $rules_str;
	
	#my %rules = map { ('toto' => $_) } @$rules;
	
	my $xml_rules = XMLout($rules, RootName => 'rules');
	
	return "can't save";
	return $xml_rules;
	
	my @monit_sets = $query->param('collect_sets[]'); # array of set name
	my @formated_monit_sets = map { { set => $_} } @monit_sets;
	
	my $graphs_settings_str = $query->param('graphs_settings'); # stringified array of hash
	my $graphs_settings = decode_json $graphs_settings_str;
		
	my $conf = $self->getMonitorConf();
	
	$conf->{generate_graph} = { graph => $graphs_settings};
	$conf->{monitor} = \@formated_monit_sets;
	
	my $xml_conf = XMLout($conf, RootName => 'conf');
	
	return "$xml_conf";
}

#TODO do this in Monitor
sub getMonitoredIndicators {
	my $self = shift;
	
	my $config = XMLin("/etc/kanopya/monitor.conf");
	my $all_conf = General::getAsArrayRef( data => $config, tag => 'conf' );
	my @conf = grep { $_->{label} eq $config->{use_conf} } @$all_conf;
	my $conf = shift @conf;
	
	my $monit_sets = General::getAsArrayRef( data => $conf, tag => 'monitor' );
	my $all_sets = General::getAsArrayRef( data => $config, tag => 'set' );

	my %indicators = ();
	foreach my $set (@$all_sets) {
		if ( scalar grep { $_->{set} eq $set->{label} } @$monit_sets ) {
			my @ds_list = map { $_->{label} } @{ General::getAsArrayRef( data => $set, tag => 'ds' ) };
			$indicators{$set->{label}} = \@ds_list;
		}
	}

	return %indicators;
}

sub view_orchestrator_settings : StartRunmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Orchestrator/view_orchestrator_settings.tmpl');
	

	my %indicators = $self->getMonitoredIndicators;
	my @choices = ();
	while ( my ($set_name, $ds_list) = each %indicators ) {
		push( @choices, map { "$set_name:" . $_ } @$ds_list) ;
	}	
	$var_choices = join ",", @choices;
	
	my $conf = $self->getOrchestratorConf();
	my @rules = ();
	my $traps =  General::getAsArrayRef( data => $conf->{add_rules}, tag => 'traps' );
	foreach my $trap (@$traps) {
		my $thresholds = General::getAsArrayRef( data => $trap, tag => 'threshold' );
		foreach my $thresh (@$thresholds) {
			push @rules, { 	var => $trap->{set} .':'. $thresh->{var}, time_laps => $trap->{time_laps},
							inf => defined $thresh->{min},
							value => defined $thresh->{max} ? $thresh->{max} : $thresh->{min},
							action => 'Add node',
							
							var_choices => $var_choices,
						};
		}
	}
	my $conditions =  General::getAsArrayRef( data => $conf->{delete_rules}, tag => 'conditions' );
	foreach my $cond (@$conditions) {
		my $required = General::getAsArrayRef( data => $cond, tag => 'required' );
		foreach my $req (@$required) {
			push @rules, { 	var => $cond->{set} .':'. $req->{var}, time_laps => $cond->{time_laps},
							inf => defined $req->{max},
							value => defined $req->{max} ? $req->{max} : $req->{min},
							action => 'Remove node',
							
							var_choices => $var_choices,
						};
		}
	}
	
	
	$tmpl->param('RULES' => \@rules);
	$tmpl->param('VAR_CHOICES' => $var_choices);
	$tmpl->param('TITLEPAGE' => "Orchestrator settings");
	$tmpl->param('MSETTINGS' => 1);
	$tmpl->param('SUBMORCHESTRATOR' => 1);
	
	return $tmpl->output();
}


1;
