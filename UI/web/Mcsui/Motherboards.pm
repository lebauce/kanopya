package Mcsui::Motherboards;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Forward;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

sub view_motherboardn : StartRunmode {
    my $self = shift;
    my $output = '';
    my @emotherboards = $self->{'admin'}->getEntities(type => 'Motherboard', hash => {});
    my $motherboards = [];
    my $details = [];

    foreach my $n (@emotherboards){
	my $tmp = {};
	$tmp->{ID} = $n->getAttr(name => 'motherboard_id');
	$tmp->{POSITION} = $n->getAttr(name => 'motherboard_slot_position');
	my $model = $self->{'admin'}->getEntity(type => 'Motherboard_model', id => $n->getAttr(name => 'motherboard_model_id'));
	$tmp->{MODEL} = $model->getAttr(name =>'motherboard_brand')." ".$model->getAttr(name => 'motherboard_model_name');
	$tmp->{ACTIVE} = $n->getAttr(name => 'active');
	push (@$motherboards, $tmp);
    }
		
    foreach my $m (@emotherboards) {
    	my $tmp = {};
	$tmp->{ID} = $m->getAttr(name => 'motherboard_id');
	$tmp->{SN} = $m->getAttr(name => 'motherboard_serial_number');
	$tmp->{MAC} = $m->getAttr(name => 'motherboard_mac_address');
	my $processor = $self->{'admin'}->getEntity(type => 'Processor_model', id => $m->getAttr(name => 'processor_model_id'));
	$tmp->{CPU} = $processor->getAttr(name => 'processor_brand')." ".$processor->getAttr(name => 'processor_model_name');
	$tmp->{CORES} = $processor->getAttr(name => 'processor_core_num');
	my $motherboard = $self->{'admin'}->getEntity(type => 'Motherboard_model', id => $m->getAttr(name => 'motherboard_model_id'));
	$tmp->{RAM} = $motherboard->getAttr(name => 'motherboard_RAM_max');
	$tmp->{CONSUMPTION} = $motherboard->getAttr(name =>'motherboard_consumption'); 
	$tmp->{IP} = $m->getAttr(name => 'motherboard_internal_ip');
	my $kernel= $self->{'admin'}->getEntity(type => 'Kernel', id => $m->getAttr(name => 'kernel_id'));
	$tmp->{KERNEL} = $kernel->getAttr(name => 'kernel_version')." ".$kernel->getAttr(name => 'kernel_name'); 
	$tmp->{DESC} = $m->getAttr(name => 'motherboard_desc');
        push (@$details, $tmp); 
    }
    
    my $tmpl =  $self->load_tmpl('view_motherboards.tmpl');
    $tmpl->param('TITLE_PAGE' => "Motherboards View");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MOTHERBOARDS' => 1);
	
	$tmpl->param('USERID' => 1234);
	$tmpl->param('MOTHERBOARDS' => $motherboards);
	$tmpl->param('DETAILS' => $details);
	
	$output .= $tmpl->output();
        
    return $output;	
}

sub form_addmotherboard : Runmode {
    my $self = shift;
    my $errors = shift;
    my $output = '';
    my $tmpl =  $self->load_tmpl('form_addmotherboard.tmpl');
    $tmpl->param('TITLE_PAGE' => "Adding a Motherboard");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MOTHERBOARDS' => 1);
	$tmpl->param($errors) if $errors;
	
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

sub _addmotherboard_profile {
	return {
		required => 'mac_address',
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

1;
