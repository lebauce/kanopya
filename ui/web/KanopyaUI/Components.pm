package KanopyaUI::Components;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Component;
use Data::Dumper;
use Log::Log4perl "get_logger";
use Entity::Cluster;
use Entity::Component;
use JSON;

my $log = get_logger("webui");

# translate all special characters to be not interpreted as html
# For a multilevel conf structure
# This allow special char in configuration input

sub _deepEscapeHtml {
	my $data = shift;
	
	while( my ($key, $value) = each %$data) {
		if (ref $value eq "ARRAY") {
			foreach (@$value) { _deepEscapeHtml( $_ ); }
		} else {
			$data->{$key} = CGI::escapeHTML( $value );	
		}
	}
}

# components listing available 

sub view_components : StartRunmode {
	my $self = shift;
	my $tmpl =  $self->load_tmpl('Components/view_components.tmpl');
	$tmpl->param('titlepage' => "Systems - Components");
    $tmpl->param('mSystems' => 1);
	$tmpl->param('submComponents' => 1);
	$tmpl->param('username' => $self->session->param('username'));
	
	my $components = [];
	$components = Entity::Component->getComponentsByCategory();
	
	$tmpl->param('components_list' => $components);
	return $tmpl->output();
}

# get component configuration from database and send it to the appropriate form

sub form_configurecomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	my $component_instance_id = $query->param('component_instance_id'); 
	my $component = Entity::Component->getInstance(id=>$component_instance_id);
	my $cluster_id = $component->getAttr(name=>'cluster_id');
	my $ecluster = Entity::Cluster->get(id => $cluster_id);
	my $componentdetail = $component->getComponentAttr();
	my $tmplfile = 'Components/form_'.lc($componentdetail->{component_name}).$componentdetail->{component_version}.'.tmpl';
	my $tmpl =$self->load_tmpl($tmplfile);
		
	my $config = $component->getConf();
	_deepEscapeHtml( $config );
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
	my $component = Entity::Component->getInstance(id=>$component_instance_id);
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
		my $elem = $conf;
		for (my $i = 0; $i <= @items-2; $i += 2) {
	    		if (not defined $elem->{$items[$i]}[$items[$i+1]] ) { $elem->{$items[$i]}[$items[$i+1]] = {}; }
	    		$elem = $elem->{$items[$i]}[$items[$i+1]];
		}
		$elem->{$items[-1]} = $query->param($field);
		
#		if(scalar(@items) == 1) { 
#			$conf->{$items[0]} = $query->param($field); 
#		} else {
#			if(not exists $conf->{$items[0]}) { $conf->{$items[0]} = []; }
#			elsif(not scalar(@{$conf->{$items[0]}})) { $conf->{$items[0]}[$items[1]] = {}; }
#			$conf->{$items[0]}[$items[1]]->{$items[2]} = $query->param($field);
#		}
	} 
	#$output .= Dumper($conf)."<br /><br />";
	$component->setConf($conf);
	$self->redirect("/cgi/kanopya.cgi/clusters/view_clusterdetails?cluster_id=".$cluster_id);
}


sub process_configurecomponent_from_json : Runmode {
	my $self = shift;
	my $errors = shift;
	my $query = $self->query();
	
	my $component_instance_id = $query->param('component_instance_id'); 
	
	my $component = Entity::Component->getInstance(id=>$component_instance_id);
	
	my $conf_str = $query->param('conf'); # stringified conf
	my $conf = decode_json $conf_str;
	
	foreach ('cluster_id', 'component_name', 'component_instance_id') { delete $conf->{$_}; }
	
	my $msg = "conf saved";
	eval {
		$component->setConf($conf);
	};
	if ($@) {
		$msg = "Error while saving:\n $@";
	}

	return $msg;
}

# form_uploadcomponent popup window

sub form_uploadcomponent : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl =$self->load_tmpl('Components/form_uploadcomponent.tmpl');
	$tmpl->param($errors) if $errors;
	
	return $tmpl->output();
}

# fields verification function to used with form_uploadcomponent

sub _uploadcomponent_profile {
	return {
		required => 'componentfile',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

# uploadcomponent processing

sub process_uploadcomponent : Runmode {
	my $self = shift;
	use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_uploadcomponent', '_uploadcomponent_profile');
    return $err_page if $err_page;
	my $query = $self->query();
	my $filename = $query->param('componentfile');
	open (OUTFILE, ">>/tmp/$filename");
	my $buffer;
	while (my $bytesread = read($filename, $buffer, 1024)) {
  		print OUTFILE $buffer;
	}
	close OUTFILE;
	
	eval {

		Operation->enqueue(
			priority => 200,
			type     => 'DeployComponent',
			params   => { file_path => "/tmp/$filename" },
		);
		
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');	
		}
		else { $exception->rethrow(); }
	}
	else {	
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'new component upload added to execution queue'); 
		return $self->close_window();
	} 		
}
