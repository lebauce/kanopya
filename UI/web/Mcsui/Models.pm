package Mcsui::Models;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use Data::Dumper;

sub setup {
	my $self = shift;
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

# models listing

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

# processor model 

sub form_addprocessormodel : Runmode {
    my $self = shift;
    my $errors = shift;
    my $output = '';
    my $tmpl =  $self->load_tmpl('form_addprocessormodel.tmpl');
    $tmpl->param('TITLE_PAGE' => "Adding a Processor model");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MODELS' => 1);
	$tmpl->param($errors) if $errors;
	
	$tmpl->param('USERID' => 1234);
	$output .= $tmpl->output();
	return $output;
}

sub process_addprocessormodel : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addprocessormodel', '_addprocessormodel_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    eval {
		my $procmodel = $self->{admin}->newEntity( type => 'Processormodel', params => {
			processormodel_brand => $query->param('brand'),
			processormodel_name => $query->param('name'),
			processormodel_core_num => $query->param('coresnum'),
			processormodel_clock_speed => $query->param('clockspeed'),
			processormodel_fsb => $query->param('fsb'),
			processormodel_l2_cache => $query->param('l2cache'),
			processormodel_max_consumption => $query->param('consumption'),
			processormodel_max_tdp => $query->param('tdp'),
			processormodel_64bits => $query->param('is64bits'),
			processormodel_cpu_flags => $query->param('cpuflags'),
		});
		$procmodel->save();
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'new processor model created'); }
    $self->forward('view_models');
}

sub _addprocessormodel_profile {
	return {
		required => [ qw(brand name consumption) ],
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}

# motherboard model

sub form_addmotherboardmodel : Runmode {
    my $self = shift;
    my $errors = shift;
    my $output = '';
    my $tmpl =  $self->load_tmpl('form_addmotherboardmodel.tmpl');
    $tmpl->param('TITLE_PAGE' => "Adding a Motherboard model");
	$tmpl->param('MENU_CONFIGURATION' => 1);
	$tmpl->param('SUBMENU_MODELS' => 1);
	$tmpl->param($errors) if $errors;
	
	my @processormodels = $self->{'admin'}->getEntities(type => 'Processormodel', hash => {});
	my $pmodels = [];
	foreach my $x (@processormodels){
		my $tmp = {
			ID => $x->getAttr( name => 'processormodel_id'),
		    NAME => join(' ',$x->getAttr(name =>'processormodel_brand'),$x->getAttr(name => 'processormodel_name')),
		};
		push (@$pmodels, $tmp);
	}
	$tmpl->param('PROCMODEL' => $pmodels);
	$tmpl->param('USERID' => 1234);
	$output .= $tmpl->output();
	return $output;
}

sub process_addmotherboardmodel : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addmotherboardmodel', '_addmotherboardmodel_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    eval {
		my $mothmodel = $self->{admin}->newEntity( type => 'Motherboardmodel', params => {
			motherboardmodel_brand => $query->param('brand'),
			motherboardmodel_name => $query->param('name'),
			motherboardmodel_chipset => $query->param('chipset'),
			motherboardmodel_processor_num => $query->param('procnum'),
			motherboardmodel_consumption => $query->param('consumption'),
			motherboardmodel_iface_num => $query->param('ifacenum'),
			motherboardmodel_ram_slot_num => $query->param('ramslotnum'),
			motherboardmodel_ram_max => $query->param('rammax'),
			processormodel_id => $query->param('processorid') ne '0' ? $query->param('processorid') : undef,
			
		});
		$mothmodel->save();
    };
    if($@) { 
		my $error = $@;
		$self->{'admin'}->addMessage(type => 'error', content => $error); 
	} else { $self->{'admin'}->addMessage(type => 'success', content => 'new motherboard model created'); }
    $self->redirect('/cgi/mcsui.cgi/models/view_models');
}

sub _addmotherboardmodel_profile {
	return {
		required => [ qw(brand name consumption) ],
		msgs => {
				any_errors => 'some_errors',
				prefix => 'err_'
		},
	};
}


1;
