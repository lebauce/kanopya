package Mcsui::Motherboards;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use Data::Dumper;
use strict;
use warnings;

sub setup {
	my $self = shift;
	my $tmpl_path = [
		'/opt/kanopya/ui/web/Mcsui/templates',
		'/opt/kanopya/ui/web/Mcsui/templates/Motherboards'];
	$self->tmpl_path($tmpl_path);
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

# motherboards listing page

sub view_motherboards : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('view_motherboards.tmpl');
    # header / menu variables
    $tmpl->param('titlepage' => "Hardware - Motherboards");
	$tmpl->param('mHardware' => 1);
    $tmpl->param('submMotherboards' => 1);
   
    my @emotherboards = $self->{'admin'}->getEntities(type => 'Motherboard', hash => {});
    my $motherboards = [];

    foreach my $m (@emotherboards) {
		my $tmp = {};
		$tmp->{link_activity} = 0;
		
		$tmp->{motherboard_id} = $m->getAttr(name => 'motherboard_id');
#		$tmp->{POSITION} = $m->getAttr(name => 'motherboard_powersupply_id');
		my $emodel = $self->{'admin'}->getEntity(type => 'Motherboardmodel', id => $m->getAttr(name => 'motherboardmodel_id'));
		$tmp->{motherboard_model} = $emodel->getAttr(name =>'motherboardmodel_brand')." ".$emodel->getAttr(name => 'motherboardmodel_name');
		$tmp->{motherboard_state} = $m->getAttr(name => 'motherboard_state');
		$tmp->{motherboard_hostname} = $m->getAttr(name => 'motherboard_hostname');
		$tmp->{motherboard_ip} = $m->getAttr(name => 'motherboard_internal_ip');
		$tmp->{active} = $m->getAttr(name => 'active');
#		$tmp->{SN} = $m->getAttr(name => 'motherboard_serial_number');
#		$tmp->{MAC} = $m->getAttr(name => 'motherboard_mac_address');
#		my $eprocessor = $self->{'admin'}->getEntity(type => 'Processormodel', id => $m->getAttr(name => 'processormodel_id'));
#		$tmp->{CPU} = $eprocessor->getAttr(name => 'processormodel_brand')." ".$eprocessor->getAttr(name => 'processormodel_name');
#		$tmp->{CORES} = $eprocessor->getAttr(name => 'processormodel_core_num');
#		my $emotherboard = $self->{'admin'}->getEntity(type => 'Motherboardmodel', id => $m->getAttr(name => 'motherboardmodel_id'));
#		$tmp->{motherboardmodel_name} = $emotherboard->getAttr(name => 'motherboardmodel_ram_max');
#		$tmp->{RAM} = $emotherboard->getAttr(name => 'motherboardmodel_ram_max');
#		$tmp->{CONSUMPTION} = $emotherboard->getAttr(name =>'motherboardmodel_consumption'); 
		
#		my $ekernel= $self->{'admin'}->getEntity(type => 'Kernel', id => $m->getAttr(name => 'kernel_id'));
#		$tmp->{KERNEL} = $ekernel->getAttr(name => 'kernel_version'); 
		if($tmp->{motherboard_state} =~ /(up)|(starting)/) {
			my $ecluster = $self->{'admin'}->getEntity(type => 'Cluster', id => $m->getClusterId());
			$tmp->{cluster_name} =$ecluster->getAttr('name' => 'cluster_name');
			$tmp->{link_activity} = 1;
		} else {
			$tmp->{cluster_name} = '';
			
		}
		$tmp->{motherboard_desc} = $m->getAttr(name => 'motherboard_desc');
    
		push (@$motherboards, $tmp);
    }
		
    $tmpl->param('motherboards_list' => $motherboards);       
    return $tmpl->output();	
}

# motherboard creation popup window

sub form_addmotherboard : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('form_addmotherboard.tmpl');
    
    
	$tmpl->param($errors) if $errors;

	my @motherboardmodels = $self->{'admin'}->getEntities(type => 'Motherboardmodel', hash => {});
	my @processormodels = $self->{'admin'}->getEntities(type => 'Processormodel', hash => {});
	my @kernel = $self->{'admin'}->getEntities(type => 'Kernel', hash => {});
	
	my $mmodels = [];
	foreach my $x (@motherboardmodels){
		my $tmp = {
			ID => $x->getAttr( name => 'motherboardmodel_id'),
		    NAME => join(' ',$x->getAttr(name =>'motherboardmodel_brand'),$x->getAttr(name => 'motherboardmodel_name')),
		    #PROCID => $x->getAttr( name => 'processormodel_id'),
		};
		push (@$mmodels, $tmp);
	}
	
	my $pmodels = [];
	foreach my $x (@processormodels){
		my $tmp = {
			ID => $x->getAttr( name => 'processormodel_id'),
		    NAME => join(' ',$x->getAttr(name =>'processormodel_brand'),$x->getAttr(name => 'processormodel_name')),
		};
		push (@$pmodels, $tmp);
	}
	
	my $kern = [];
	foreach my $x (@kernel){
		my $tmp = {
			ID => $x->getAttr( name => 'kernel_id'),
		    NAME => $x->getAttr(name => 'kernel_version'),
		};
		push (@$kern, $tmp);
	}
	
	$tmpl->param('MOTHERBOARDMODELS' => $mmodels);
	$tmpl->param('PROCESSORMODELS' => $pmodels);
	$tmpl->param('KERNEL' => $kern);
	$tmpl->param('USERID' => 1234);
	
	return $tmpl->output();
}

# form_addmotherboard processing

sub process_addmotherboard : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addmotherboard', '_addmotherboard_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "AddMotherboard", priority => '100', params => { 
		motherboard_mac_address => $query->param('mac_address'), 
		kernel_id => $query->param('kernel'), , 
		motherboard_serial_number => $query->param('serial_number'), 
		motherboardmodel_id => $query->param('motherboard_model'), 
		processormodel_id => $query->param('cpu_model'), 
		motherboard_desc => $query->param('desc') });
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'new motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}

# fields verification function to used with form_addmotherboard

sub _addmotherboard_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

# motherboard details page

sub view_motherboarddetails : Runmode {
	my $self = shift;
	my $errors = shift;
	my $tmpl = $self->load_tmpl('view_motherboarddetails.tmpl');
	
	 # header / menu variables
	$tmpl->param('titlepage' => "Motherboard's overview");
	$tmpl->param('mHardware' => 1);
	$tmpl->param('submMotherboards' => 1);
	
	# actions visibility
	#$tmpl->param('link_delete' => 0);
	$tmpl->param('link_activate' => 0);
	
	my $query = $self->query();
	my $emotherboard = $self->{'admin'}->getEntity(type => 'Motherboard', id => $query->param('motherboard_id'));
	my $emmodel = $self->{'admin'}->getEntity(type => 'Motherboardmodel', id => $emotherboard->getAttr(name => 'motherboardmodel_id'));
	my $epmodel = $self->{'admin'}->getEntity(type => 'Processormodel', id => $emotherboard->getAttr(name => 'processormodel_id'));
	my $ekernel = $self->{'admin'}->getEntity(type => 'Kernel', id => $emotherboard->getAttr(name => 'kernel_id'));
	
	$tmpl->param('motherboard_hostname' => $emotherboard->getAttr('name' => 'motherboard_hostname'));
	$tmpl->param('motherboard_desc' => $emotherboard->getAttr('name' => 'motherboard_desc'));
	$tmpl->param('motherboard_model' => $emmodel->getAttr(name =>'motherboardmodel_brand')." ".$emmodel->getAttr(name => 'motherboardmodel_name'));
	$tmpl->param('processor_model' => $epmodel->getAttr(name =>'processormodel_brand')." ".$epmodel->getAttr(name => 'processormodel_name'));
	$tmpl->param('motherboard_mac' => $emotherboard->getAttr('name' => 'motherboard_mac_address'));
	$tmpl->param('motherboard_ip' => $emotherboard->getAttr('name' => 'motherboard_internal_ip'));
	$tmpl->param('motherboard_sn' => $emotherboard->getAttr('name' => 'motherboard_serial_number'));
	$tmpl->param('motherboard_powersupply' => $emotherboard->getAttr('name' => 'motherboard_powersupply_id'));
	$tmpl->param('motherboard_kernel' => $ekernel->getAttr('name' => 'kernel_name'));
	
	if($emotherboard->getAttr('name' => 'active')) {
		$tmpl->param('active' => 1);
		$tmpl->param('link_activate' => 0);
	
		my $state = $emotherboard->getAttr('name' => 'motherboard_state');
		if($state =~ /up/) {
			$tmpl->param('motherboard_state' => 'Up'); 
		} elsif($state =~ /starting/) {
			$tmpl->param('motherboard_state' => 'Starting...');
		} elsif($state =~ /stopping/) {
			$tmpl->param('motherboard_state' => 'Stopping...');
		} elsif($state =~ /down/) {
			$tmpl->param('motherboard_state' => 'down');
		}
	} else {
		$tmpl->param('active' => 0);
		$tmpl->param('link_activate' => 1);
		$tmpl->param('motherboard_state' => '');
	}
	
	return $tmpl->output();
}

sub process_activatemotherboard : Runmode {
    my $self = shift;
        
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "ActivateMotherboard", priority => '100', params => { 
		motherboard_id => $query->param('motherboard_id'), 
		});
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'activate motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}

sub process_deactivatemotherboard : Runmode {
    my $self = shift;
        
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "DeactivateMotherboard", priority => '100', params => { 
		motherboard_id => $query->param('motherboard_id'), 
		});
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'deactivate motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}

sub process_removemotherboard : Runmode {
    my $self = shift;
        
    my $query = $self->query();
    eval {
    $self->{'admin'}->newOp(type => "RemoveMotherboard", priority => '100', params => { 
		motherboard_id => $query->param('motherboard_id'), 
		});
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'newop', content => 'remove motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}

1;
