package Mcsui::Orchestration;
use Data::Dumper;
use base 'CGI::Application';
use Log::Log4perl "get_logger";
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use XML::Simple;
use JSON;
		
use lib "/workspace/mcs/Orchestrator/Lib";

my $log = get_logger("administrator");


sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'admin', password => 'admin');
}


=head2 save_monitoring_settings
	
	Class : Public
	
	Desc : 	Called by client to save monitoring settings.
			Transform: query params (json) -> perl type (according to xml conf struct) -> xml (conf) 
	
=cut

sub save_orchestrator_settings : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	
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

sub view_orchestrator_settings : StartRunmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('view_orchestrator_settings.tmpl');
	
	
	$tmpl->param('TITLE_PAGE' => "Orchestrator settings");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	
	return $tmpl->output();
}


1;
