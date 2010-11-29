package Mcsui::Components;
use Data::Dumper;
use base 'CGI::Application';
use Log::Log4perl "get_logger";
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use strict;
use warnings;

my $log = get_logger("administrator");

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub form_configurecomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	my $component_instance_id = $query->param('component_instance_id'); 
	my $component = $self->{'admin'}->getComponent(component_instance_id=>$component_instance_id);
	my $cluster_id = $component->getAttr(name=>'cluster_id');
	my $ecluster = $self->{'admin'}->getEntity(type => 'Cluster', id=>$cluster_id);
	my $componentdetail = $component->getComponentAttr();
	my $tmplfile = 'form_'.lc($componentdetail->{component_name}).$componentdetail->{component_version}.'.tmpl';
	my $tmpl =$self->load_tmpl($tmplfile);
		
	my $config = $component->getConf();
	while( my ($key, $value) = each %$config) {
		$tmpl->param($key => $value);	
	}
	
	$tmpl->param('COMPONENT_INSTANCE_ID' => $component_instance_id);
	$tmpl->param('CLUSTER_ID' => $cluster_id);
	$tmpl->param('CLUSTER_NAME' => $ecluster->getAttr(name => 'cluster_name'));
	$tmpl->param('TITLE_PAGE' => "Component Configuration : $componentdetail->{COMPNAME}");
	$tmpl->param('MENU_CLUSTERSMANAGEMENT' => 1);
	
	return $tmpl->output();
}



sub process_configurecomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	my $conf = {};
	my $output = '';
	
	my $component_instance_id = $query->param('component_instance_id'); 
	my $component = $self->{'admin'}->getComponent(component_instance_id=>$component_instance_id);
	my $cname = quotemeta(lc($query->param('component_name')));
	
	my @fields = $query->param;
		
	while(scalar(@fields)) {
		my $field = shift(@fields);
		if($field eq 'component_instance_id' or $field eq 'component_name') {
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
	$output .= Dumper($conf)."<br /><br />";
	$output .= $component->setConf($conf);
	return $output;
}

