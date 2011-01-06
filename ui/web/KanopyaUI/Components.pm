package KanopyaUI::Components;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("administrator");

# components listing available 

sub view_components : StartRunmode {
	my $self = shift;
	my $tmpl =  $self->load_tmpl('Components/view_components.tmpl');
	$tmpl->param('titlepage' => "Systems - Components");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submComponents' => 1);
	
	my $components = [];
	$components = $self->{admin}->getComponentsListByCategory();
	
	$tmpl->param('components_list' => $components);
	return $tmpl->output();
}

# get component configuration from database and send it to the appropriate form

sub form_configurecomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	my $component_instance_id = $query->param('component_instance_id'); 
	my $component = $self->{'admin'}->getComponent(component_instance_id=>$component_instance_id);
	my $cluster_id = $component->getAttr(name=>'cluster_id');
	my $ecluster = $self->{'admin'}->getEntity(type => 'Cluster', id=>$cluster_id);
	my $componentdetail = $component->getComponentAttr();
	my $tmplfile = 'Components/form_'.lc($componentdetail->{component_name}).$componentdetail->{component_version}.'.tmpl';
	my $tmpl =$self->load_tmpl($tmplfile);
		
	my $config = $component->getConf();
	while( my ($key, $value) = each %$config) {
		$tmpl->param($key => $value);	
	}
	
	$tmpl->param('COMPONENT_INSTANCE_ID' => $component_instance_id);
	$tmpl->param('cluster_id' => $cluster_id);
	$tmpl->param('CLUSTER_NAME' => $ecluster->getAttr(name => 'cluster_name'));
	$tmpl->param('titlepage' => "Component Configuration : $componentdetail->{COMPNAME}");
	$tmpl->param('mClusters' => 1);
	$tmpl->param('submClusters' => 1);
	
	return $tmpl->output();
}

# retrieve component configuration from interface and save it to the database

sub process_configurecomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	my $conf = {};
	my $output = '';
	
	my $component_instance_id = $query->param('component_instance_id'); 
	my $component = $self->{'admin'}->getComponent(component_instance_id=>$component_instance_id);
	my $cluster_id = $query->param('cluster_id'); 
	my $cname = quotemeta(lc($query->param('component_name')));
	# quotemeta : Returns the value of EXPR with all non-"word" characters backslashed
	
	my @fields = $query->param;
		
	while(scalar(@fields)) {
		my $field = shift(@fields);
		if($field eq 'component_instance_id' or $field eq 'component_name' or $field eq 'cluster_id') {
			next;
		}
		
		my @items = split(/-/, $field);
		if(scalar(@items) == 1) { 
			$conf->{$items[0]} = $query->param($field); 
		} else { 
			if(not exists $conf->{$items[0]}) { $conf->{$items[0]} = []; }
			elsif(not scalar(@{$conf->{$items[0]}})) { $conf->{$items[0]}[$items[1]] = {}; }
			$conf->{$items[0]}[$items[1]]->{$items[2]} = $query->param($field);
		}
	} 
	#$output .= Dumper($conf)."<br /><br />";
	$component->setConf($conf);
	$self->redirect("/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id=".$cluster_id);
}

