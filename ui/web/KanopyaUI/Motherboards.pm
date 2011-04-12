package KanopyaUI::Motherboards;
use base 'KanopyaUI::CGI';

use Data::Dumper;
use strict;
use warnings;
use Entity::Motherboard;
use Entity::Kernel;
use Entity::Cluster;
use Entity::Processormodel;
use Entity::Motherboardmodel;
use Entity::Powersupplycard;


# motherboards listing page

sub view_motherboards : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('Motherboards/view_motherboards.tmpl');
    # header / menu variables
    $tmpl->param('titlepage' => "Hardware - Motherboards");
	$tmpl->param('mHardware' => 1);
    $tmpl->param('submMotherboards' => 1);
    $tmpl->param('username' => $self->session->param('username'));  
 
    my @emotherboards = Entity::Motherboard->getMotherboards(hash => {});
    my $motherboards = [];

    foreach my $m (@emotherboards) {
		my $tmp = {};
		$tmp->{link_activity} = 0;
		$tmp->{state_up} = 0;
		$tmp->{state_down} = 0;
		$tmp->{state_starting} = 0;
		$tmp->{state_stopping} =0;
		$tmp->{state_broken} = 0;
		
		$tmp->{motherboard_id} = $m->getAttr(name => 'motherboard_id');
		
		$tmp->{motherboard_label} = $m->toString();
		my $state = $m->getAttr(name => 'motherboard_state');
		#$tmp->{motherboard_mac} = $m->getAttr(name => 'motherboard_mac_address');
		$tmp->{motherboard_hostname} = $m->getAttr(name => 'motherboard_hostname');
		$tmp->{motherboard_ip} = $m->getAttr(name => 'motherboard_internal_ip');
		$tmp->{active} = $m->getAttr(name => 'active');
 		 
		if($tmp->{active}) {
			if($state =~ /up/) {
				$tmp->{state_up} = 1;
				$tmp->{link_activity} = 1;
			} elsif($state =~ /starting/)  {
				$tmp->{state_starting} = 1;
			} elsif($state =~ /stopping/)  {
				$tmp->{state_stopping} = 1;
			} elsif ($state =~ /down/)  {
				$tmp->{state_down} = 1;
			} elsif($state =~ /broken/)  {
				$tmp->{state_broken} = 1;
				$tmp->{link_activity} = 1;
			}
		}
				
		$tmp->{motherboard_desc} = $m->getAttr(name => 'motherboard_desc');
    	push (@$motherboards, $tmp);
    }
		
    $tmpl->param('motherboards_list' => $motherboards);
    
    my $methods = Entity::Motherboard->getPerms();
    if($methods->{'create'}->{'granted'}) { $tmpl->param('can_create' => 1); }
          
    return $tmpl->output();	
}

# motherboard creation popup window

sub form_addmotherboard : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('Motherboards/form_addmotherboard.tmpl');
    $tmpl->param($errors) if $errors;

	my @motherboardmodels = Entity::Motherboardmodel->getMotherboardmodels(hash => {});
	my @processormodels = Entity::Processormodel->getProcessormodels(hash => {});
	my @kernel = Entity::Kernel->getKernels(hash => {});
	my @powersupplycards = Entity::Powersupplycard->getPowerSupplyCards(hash => {});
	
	my $mmodels = [];
	foreach my $x (@motherboardmodels){
		my $tmp = {
			ID => $x->getAttr( name => 'motherboardmodel_id'),
		    NAME => join(' ',$x->getAttr(name =>'motherboardmodel_brand'),$x->getAttr(name => 'motherboardmodel_name')),
		    #PROCID => $x->getAttr( name => 'processormodel_id'),
		};
		push (@$mmodels, $tmp);
	}
	$tmpl->param('MOTHERBOARDMODELS' => $mmodels);
	
	my $pmodels = [];
	foreach my $x (@processormodels){
		my $tmp = {
			ID => $x->getAttr( name => 'processormodel_id'),
		    NAME => join(' ',$x->getAttr(name =>'processormodel_brand'),$x->getAttr(name => 'processormodel_name')),
		};
		push (@$pmodels, $tmp);
	}
	$tmpl->param('PROCESSORMODELS' => $pmodels);
	
	my $kern = [];
	foreach my $x (@kernel){
		my $tmp = {
			ID => $x->getAttr( name => 'kernel_id'),
		    NAME => $x->getAttr(name => 'kernel_version'),
		};
		push (@$kern, $tmp);
	}
	$tmpl->param('KERNEL' => $kern);
	
	
	my $pscards = [];
	foreach my $x (@powersupplycards){
		my $tmp = {
			powersupplycard_id => $x->getAttr( name => 'powersupplycard_id'),
		    powersupplycard_name => $x->getAttr(name => 'powersupplycard_name'),
		};
		push (@$pscards, $tmp);
	}
	
	$tmpl->param('powersupplycards' => $pscards);
		
	return $tmpl->output();
}

# form_addmotherboard processing

sub process_addmotherboard : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addmotherboard', '_addmotherboard_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    my %params = (
    	motherboard_mac_address => $query->param('mac_address'), 
		kernel_id => $query->param('kernel'), , 
		motherboard_serial_number => $query->param('serial_number'), 
		motherboardmodel_id => $query->param('motherboard_model'), 
		processormodel_id => $query->param('cpu_model'), 
		motherboard_desc => $query->param('desc'),
	);
	if($query->param('powersupplycard_id') ne "none") {
		$params{powersupplycard_id} = $query->param('powersupplycard_id'),
		$params{powersupplyport_number} => $query->param('powersupplyport_number'),
    }
    my $motherboard = Entity::Motherboard->new(%params);     
	eval { $motherboard->create() };
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
    else { 
    	$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'host creation adding to execution queue');
    	return $self->close_window(); 
    }
}

# fields verification function to used with form_addmotherboard

sub _addmotherboard_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_',
				constraints => {
        			'mac_address_valid' => 'Invalid MAC address format',
        		}
		},
		constraint_methods => {
        	mac_address => mac_address_valid(),
        }
	};
}

# function constraint for mac_address field used in _addmotherboard_profile

sub mac_address_valid {
	return sub {
		my $dfv = shift;
		$dfv->name_this('mac_address_valid');
		my $mac = $dfv->get_current_constraint_value();
		return ($mac =~ /^[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}$/);
	}
}

# motherboard details page

sub view_motherboarddetails : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('Motherboards/view_motherboarddetails.tmpl');
	
	 # header / menu variables
	$tmpl->param('titlepage' => "Motherboard's overview");
	$tmpl->param('mHardware' => 1);
	$tmpl->param('submMotherboards' => 1);
	$tmpl->param('username' => $self->session->param('username'));
		
	# motherboard state
	$tmpl->param('state_up' => 0);
	$tmpl->param('state_down' => 0);
	$tmpl->param('state_broken' => 0);
	$tmpl->param('state_starting' => 0);
	$tmpl->param('state_stopping' => 0);
	
	my $query = $self->query();
	my $emotherboard = Entity::Motherboard->get(id => $query->param('motherboard_id'));
	$tmpl->param('motherboard_id' => $emotherboard->getAttr('name' => 'motherboard_id'));
	$tmpl->param('motherboard_hostname' => $emotherboard->getAttr('name' => 'motherboard_hostname'));
	$tmpl->param('motherboard_desc' => $emotherboard->getAttr('name' => 'motherboard_desc'));
	$tmpl->param('motherboard_mac' => $emotherboard->getAttr('name' => 'motherboard_mac_address'));
	$tmpl->param('motherboard_ip' => $emotherboard->getAttr('name' => 'motherboard_internal_ip'));
	$tmpl->param('motherboard_sn' => $emotherboard->getAttr('name' => 'motherboard_serial_number'));
	$tmpl->param('motherboard_powersupply' => $emotherboard->getAttr('name' => 'motherboard_powersupply_id'));
		
	my $methods = $emotherboard->getPerms();
	if($methods->{'setperm'}->{'granted'}) { $tmpl->param('can_setperm' => 1); }
	
	eval {
		my $emmodel = Entity::Motherboardmodel->get(id => $emotherboard->getAttr(name => 'motherboardmodel_id'));
		$tmpl->param('motherboard_model' => $emmodel->getAttr(name =>'motherboardmodel_brand')." ".$emmodel->getAttr(name => 'motherboardmodel_name'));
	};
	eval {
		my $epmodel = Entity::Processormodel->get(id => $emotherboard->getAttr(name => 'processormodel_id'));
		$tmpl->param('processor_model' => $epmodel->getAttr(name =>'processormodel_brand')." ".$epmodel->getAttr(name => 'processormodel_name'));
	};
	eval {
		my $ekernel = Entity::Kernel->get(id => $emotherboard->getAttr(name => 'kernel_id'));
		$tmpl->param('motherboard_kernel' => $ekernel->getAttr('name' => 'kernel_name'));
	};
	
	if($emotherboard->getAttr('name' => 'active')) {
		$tmpl->param('active' => 1);
		my $state = $emotherboard->getAttr('name' => 'motherboard_state');
		if($state =~ /up/) {
			$tmpl->param('state_up' => 1);
			eval {
				my $ecluster = Entity::Cluster->get(id => $emotherboard->getClusterId());
				$tmpl->param('cluster_name' => $ecluster->getAttr('name' => 'cluster_name'));
			};
			 
		} elsif($state =~ /starting/) {
			$tmpl->param('state_starting' => 1);
			eval {
				my $ecluster = Entity::Cluster->get(id => $emotherboard->getClusterId());
				$tmpl->param('cluster_name' => $ecluster->getAttr('name' => 'cluster_name'));
			};
			
		} elsif($state =~ /stopping/) {
			$tmpl->param('state_stopping' => 1);
			
		} elsif($state =~ /down/) {
			$tmpl->param('state_down' => 1);
			if($methods->{'deactivate'}->{'granted'}) { $tmpl->param('can_deactivate' => 1); }
			
		} elsif($state =~ /broken/) {
			$tmpl->param('state_broken' => 1);
			
		}
	} else {
		$tmpl->param('active' => 0);
		if($methods->{'activate'}->{'granted'}) { $tmpl->param('can_activate' => 1); }
		if($methods->{'remove'}->{'granted'}) { $tmpl->param('can_delete' => 1); }
	}
	
	# harddisks list
	my $harddisks = $emotherboard->getHarddisks();
	my $hds= [];
	foreach my $hd (@$harddisks) {
		my $tmp = {};
		$tmp->{harddisk_id} = $hd->{harddisk_id};
		$tmp->{harddisk_device} = $hd->{harddisk_device}; 
		$tmp->{motherboard_id} = $emotherboard->getAttr(name => 'motherboard_id');
					
		if((not $methods->{'removeHarddisk'}->{'granted'}) || $emotherboard->getAttr('name' => 'active')) {
			$tmp->{link_removeHarddisk} = 0;
		} else { $tmp->{link_removeHarddisk} = 1;}
		push @$hds, $tmp;
	}
	$tmpl->param('nbharddisks' => scalar(@$hds)+1);
	$tmpl->param('harddisks_list' => $hds);
	if($methods->{'addHarddisk'}->{'granted'} && !$emotherboard->getAttr('name' => 'active')) { $tmpl->param('can_addHarddisk' => 1); }
	else { $tmpl->param('can_addHarddisk' => 0); }
	return $tmpl->output();
}

# motherboard activation processing

sub process_activatemotherboard : Runmode {
    my $self = shift;
    my $query = $self->query();
    eval {
    	my $motherboard = Entity::Motherboard->get(id => $query->param('motherboard_id'));
     	$motherboard->activate();
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
		$self->{adm}->addMessage(from => 'Administrator', level => 'info', content => 'host activation adding to execution queue');
		$self->redirect('/cgi/kanopya.cgi/motherboards/view_motherboarddetails?motherboard_id='.$query->param('motherboard_id')); 
	}
}

# motherboard deactivation processing

sub process_deactivatemotherboard : Runmode {
    my $self = shift;
    my $query = $self->query();
    eval {
    	my $motherboard = Entity::Motherboard->get(id => $query->param('motherboard_id'));
     	$motherboard->deactivate();
    };
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	} 
	else { $self->redirect('/cgi/kanopya.cgi/motherboards/view_motherboarddetails?motherboard_id='.$query->param('motherboard_id')) }
}

# motherboard deletion processing

sub process_deletemotherboard : Runmode {
    my $self = shift;
    my $query = $self->query();
    eval {
    	my $motherboard = Entity::Motherboard->get(id => $query->param('motherboard_id'));
     	$motherboard->remove();
    };
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	} 
	else { $self->redirect('/cgi/kanopya.cgi/motherboards/view_motherboards'); }
}

# harddisk addition popup window

sub form_addharddisk : Runmode {
	my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('Motherboards/form_addharddisk.tmpl');
    $tmpl->param($errors) if $errors;
    
    my $query = $self->query();
    $tmpl->param('motherboard_id' => $query->param('motherboard_id'));
    return $tmpl->output();
}

# fields verification function to used with form_addharddisk

sub _addharddisk_profile {
	return {
		required => 'device',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_',
				constraints => {
        			'device_valid' => 'Invalid device format',
        		}
		},
		constraint_methods => {
        	device => device_valid(),
        }
	};
}

# function constraint for mac_address field used in _addmotherboard_profile

sub device_valid {
	return sub {
		my $dfv = shift;
		$dfv->name_this('device_valid');
		my $device = $dfv->get_current_constraint_value();
		return ($device =~ /^\/dev\/(hd|sd)[a-z]{1}[0-9]*$/);
	}
}

# form_addharddisk processing

sub process_addharddisk : Runmode {
	my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addharddisk', '_addharddisk_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    
    eval { 
    	my $motherboard = Entity::Motherboard->get(id => $query->param('motherboard_id'));
    	$motherboard->addHarddisk(device => $query->param('device')); 
    };
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	} else { return $self->close_window(); }
}

# removeharddisk processing

sub process_removeharddisk : Runmode {
	my $self = shift;
    my $query = $self->query();
    my $motherboard;
    eval { 
    	$motherboard = Entity::Motherboard->get(id => $query->param('motherboard_id'));
    	$motherboard->removeHarddisk(harddisk_id => $query->param('harddisk_id')); 
    };
    if($@) { 
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	} 
	else { $self->redirect('/cgi/kanopya.cgi/motherboards/view_motherboarddetails?motherboard_id='.$motherboard->getAttr(name => 'motherboard_id')); }
}

1;
