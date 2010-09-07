package Mcsui::Models;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Forward;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_models : StartRunmode {
    my $self = shift;
    my $output = '';
    my @eprocessormodels = $self->{admin}->getEntities(type => 'Processormodel', hash => {});
    my @emotherboardmodels = $self->{admin}->getEntities(type => 'Motherboardmodel', hash => {});
    my $processormodels = [];
    my $motherboardmodels = [];
    
    for my $p (@eprocessormodels) {
		my $h = {};
		$h->{ID} = $p->getAttr(name => 'processormodel_id');
		$h->{BRAND} = $p->getAttr(name => 'processormodel_brand');
		$h->{NAME} = $p->getAttr(name => 'processormodel_name');
		$h->{CORENUM} = $p->getAttr(name => 'processormodel_core_num');
		$h->{CLOCKSPEED} = $p->getAttr(name => 'processormodel_clock_speed');
		$h->{FSB} = $p->getAttr(name => 'processormodel_fsb');
		$h->{L2CACHE} = $p->getAttr(name => 'processormodel_l2_cache');
		$h->{CONSUMPTION} = $p->getAttr(name => 'processormodel_max_consumption');
		$h->{TDP} = $p->getAttr(name => 'processormodel_max_tdp');
		$h->{IS64} = $p->getAttr(name => 'processormodel_64bits');
		$h->{CPUFLAGS} = $p->getAttr(name => 'processormodel_cpu_flags');
			
		push @$processormodels, $h;
	}
    
    for my $p (@emotherboardmodels) {
		my $h = {};
		$h->{ID} = $p->getAttr(name => 'motherboardmodel_id');
		$h->{BRAND} = $p->getAttr(name => 'motherboardmodel_brand');
		$h->{NAME} = $p->getAttr(name => 'motherboardmodel_name');
		$h->{CHIPSET} = $p->getAttr(name => 'motherboardmodel_chipset');
		$h->{PROCNUM} = $p->getAttr(name => 'motherboardmodel_processor_num');
		$h->{CONSUMPTION} = $p->getAttr(name => 'motherboardmodel_consumption');
		$h->{IFACENUM} = $p->getAttr(name => 'motherboardmodel_iface_num');
		$h->{RAMNUM} = $p->getAttr(name => 'motherboardmodel_ram_slot_num');
		$h->{RAMMAX} = $p->getAttr(name => 'motherboardmodel_ram_max');
		#$h->{PROCID} = $p->getAttr(name => 'processormodel_id');
			
		push @$motherboardmodels, $h;
	} 
     
        
    my $tmpl = $self->load_tmpl('view_models.tmpl');
    $tmpl->param('TITLE_PAGE' => "Models View");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MODELS' => 1);
	
	$tmpl->param('USERID' => 1234);
	$tmpl->param('PROCESSORMODELS' => $processormodels);
	$tmpl->param('MOTHERBOARDMODELS' => $motherboardmodels);
		
	$output .= $tmpl->output();
        
    return $output;	
}

sub form_addmotherboardmodel : Runmode {
    my $self = shift;
    my $errors = shift;
    my $output = '';
    my $tmpl =  $self->load_tmpl('form_addmotherboardmodel.tmpl');
    $tmpl->param('TITLE_PAGE' => "Adding a Motherboard");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MOTHERBOARDS' => 1);
	$tmpl->param($errors) if $errors;
	
	$tmpl->param('USERID' => 1234);
	$output .= $tmpl->output();
	return $output;
}

sub process_addmotherboardmodel : Runmode {
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
		motherboard_model_id => $query->param('motherboard_model'), 
		processor_model_id => $query->param('cpu_model'), 
		motherboard_desc => $query->param('desc') });
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'new motherboard operation adding to execution queue'); }
    $self->forward('view_motherboards');
}

sub _addmotherboardmodel_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

1;
