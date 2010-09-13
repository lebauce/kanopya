package Mcsui::Motherboards;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_motherboards : StartRunmode {
    my $self = shift;
    my $tmpl =  $self->load_tmpl('view_motherboards.tmpl');
    my $output = '';
    my @emotherboards = $self->{'admin'}->getEntities(type => 'Motherboard', hash => {});
    my $motherboards = [];
    my $details = [];

    foreach my $m (@emotherboards) {
		my $tmp = {};
		$tmp->{ID} = $m->getAttr(name => 'motherboard_id');
		$tmp->{POSITION} = $m->getAttr(name => 'motherboard_slot_position');
		my $emodel = $self->{'admin'}->getEntity(type => 'Motherboardmodel', id => $m->getAttr(name => 'motherboardmodel_id'));
		$tmp->{MODEL} = $emodel->getAttr(name =>'motherboardmodel_brand')." ".$emodel->getAttr(name => 'motherboardmodel_name');
		$tmp->{STATE} = $m->getAttr(name => 'motherboard_state');
		$tmp->{ACTIVE} = $m->getAttr(name => 'active');
		$tmp->{SN} = $m->getAttr(name => 'motherboard_serial_number');
		$tmp->{MAC} = $m->getAttr(name => 'motherboard_mac_address');
		my $eprocessor = $self->{'admin'}->getEntity(type => 'Processormodel', id => $m->getAttr(name => 'processormodel_id'));
		$tmp->{CPU} = $eprocessor->getAttr(name => 'processormodel_brand')." ".$eprocessor->getAttr(name => 'processormodel_name');
		$tmp->{CORES} = $eprocessor->getAttr(name => 'processormodel_core_num');
		my $emotherboard = $self->{'admin'}->getEntity(type => 'Motherboardmodel', id => $m->getAttr(name => 'motherboardmodel_id'));
		$tmp->{RAM} = $emotherboard->getAttr(name => 'motherboardmodel_ram_max');
		$tmp->{CONSUMPTION} = $emotherboard->getAttr(name =>'motherboardmodel_consumption'); 
		$tmp->{IP} = $m->getAttr(name => 'motherboard_internal_ip');
		my $ekernel= $self->{'admin'}->getEntity(type => 'Kernel', id => $m->getAttr(name => 'kernel_id'));
		$tmp->{KERNEL} = $ekernel->getAttr(name => 'kernel_name')." (".$ekernel->getAttr(name => 'kernel_version').")"; 
		$tmp->{DESC} = $m->getAttr(name => 'motherboard_desc');
    
		push (@$motherboards, $tmp);
    }
		
    $tmpl->param('TITLE_PAGE' => "Motherboards View");
	$tmpl->param('MENU_CONFIGURATION' => 1);
		
	$tmpl->param('USERID' => 1234);
	$tmpl->param('MOTHERBOARDS' => $motherboards);
	
	$output .= $tmpl->output();
        
    return $output;	
}

sub form_addmotherboard : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('form_addmotherboard.tmpl');
    my $output = '';
    $tmpl->param('TITLE_PAGE' => "Adding a Motherboard");
	$tmpl->param('MENU_CONFIGURATION' => 1);
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
		    NAME => $x->getAttr(name =>'kernel_name')." (".$x->getAttr(name => 'kernel_version').")",
		};
		push (@$kern, $tmp);
	}
	
	$tmpl->param('MOTHERBOARDMODELS' => $mmodels);
	$tmpl->param('PROCESSORMODELS' => $pmodels);
	$tmpl->param('KERNEL' => $kern);
	$tmpl->param('USERID' => 1234);
	$output .= $tmpl->output();
	return $output;
}

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
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'new motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}

sub _addmotherboard_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
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
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'activate motherboard operation adding to execution queue'); }
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
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'deactivate motherboard operation adding to execution queue'); }
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
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'remove motherboard operation adding to execution queue'); }
    $self->redirect('/cgi/mcsui.cgi/motherboards/view_motherboards');
}
1;
