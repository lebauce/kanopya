package KanopyaUI::Models;
use base 'KanopyaUI::CGI';

use strict;
use warnings;
use Entity::Motherboardmodel;
use Entity::Processormodel;

# models listing

sub view_models : StartRunmode {
    my $self = shift;
    my $tmpl = $self->load_tmpl('Models/view_models.tmpl');
    $tmpl->param('titlepage' => "Hardaware - Models");
	$tmpl->param('mHardware' => 1);
	$tmpl->param('submModels' => 1);
	$tmpl->param('username' => $self->session->param('username'));
    
    my @eprocessormodels = Entity::Processormodel->getProcessormodels(hash => {});
    my @emotherboardmodels = Entity::Motherboardmodel->getMotherboardmodels(hash => {});
    my $processormodels = [];
    my $motherboardmodels = [];
    
    for my $p (@eprocessormodels) {
		my $h = {};
		$h->{pmodel_id} = $p->getAttr(name => 'processormodel_id');
		$h->{pmodel_brand} = $p->getAttr(name => 'processormodel_brand');
		$h->{pmodel_name} = $p->getAttr(name => 'processormodel_name');
		$h->{pmodel_corenum} = $p->getAttr(name => 'processormodel_core_num');
		$h->{pmodel_clockspeed} = $p->getAttr(name => 'processormodel_clock_speed');
		$h->{pmodel_l2cache} = $p->getAttr(name => 'processormodel_l2_cache');
		$h->{pmodel_tdp} = $p->getAttr(name => 'processormodel_max_tdp');
		$h->{pmodel_is64} = $p->getAttr(name => 'processormodel_64bits');
		my $methods = $p->getPerms();
		if($methods->{'update'}->{'granted'}) { $h->{can_update} = 1; }
		if($methods->{'remove'}->{'granted'}) { $h->{can_delete} = 1; }
		if($methods->{'setperm'}->{'granted'}) { $h->{can_setperm} = 1; }
					
		push @$processormodels, $h;
	}
    
    for my $p (@emotherboardmodels) {
		my $h = {};
		$h->{mmodel_id} = $p->getAttr(name => 'motherboardmodel_id');
		$h->{mmodel_brand} = $p->getAttr(name => 'motherboardmodel_brand');
		$h->{mmodel_name} = $p->getAttr(name => 'motherboardmodel_name');
		$h->{mmodel_chipset} = $p->getAttr(name => 'motherboardmodel_chipset');
		$h->{mmodel_processornum} = $p->getAttr(name => 'motherboardmodel_processor_num');
		$h->{mmodel_consumption} = $p->getAttr(name => 'motherboardmodel_consumption');
		$h->{mmodel_ifacenum} = $p->getAttr(name => 'motherboardmodel_iface_num');
		$h->{mmodel_ramslotnum} = $p->getAttr(name => 'motherboardmodel_ram_slot_num');
		$h->{mmodel_rammax} = $p->getAttr(name => 'motherboardmodel_ram_max');
		#$h->{PROCID} = $p->getAttr(name => 'processormodel_id');
		my $methods = $p->getPerms();
		if($methods->{'update'}->{'granted'}) { $h->{can_update} = 1; }
		if($methods->{'remove'}->{'granted'}) { $h->{can_delete} = 1; }
		if($methods->{'setperm'}->{'granted'}) { $h->{can_setperm} = 1; }
			
		push @$motherboardmodels, $h;
	} 
	$tmpl->param('processormodels_list' => $processormodels);
	$tmpl->param('motherboardmodels_list' => $motherboardmodels);
	my $methods = Entity::Processormodel->getPerms();
	if($methods->{'create'}->{'granted'}) { $tmpl->param('can_createprocessormodel' => 1); }
	$methods = Entity::Motherboardmodel->getPerms();
	if($methods->{'create'}->{'granted'}) { $tmpl->param('can_createmotherboardmodel' => 1); }
	return $tmpl->output();
}

# processor model 

sub form_addprocessormodel : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('Models/form_addprocessormodel.tmpl');
    $tmpl->param($errors) if $errors;
	return $tmpl->output();
}

sub process_addprocessormodel : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addprocessormodel', '_addprocessormodel_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    my $procmodel = Entity::Processormodel->new(
		processormodel_brand => $query->param('brand'),
		processormodel_name => $query->param('name'),
		processormodel_core_num => $query->param('coresnum'),
		processormodel_clock_speed => $query->param('clockspeed'),
		#processormodel_fsb => $query->param('fsb'),
		processormodel_l2_cache => $query->param('l2cache'),
		#processormodel_max_consumption => $query->param('consumption'),
		processormodel_max_tdp => $query->param('tdp'),
		processormodel_64bits => $query->param('is64bits'),
		#processormodel_cpu_flags => $query->param('cpuflags'),
	);
    eval { $procmodel->create(); };
   	if($@) {
    	my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
	else { return $self->close_window(); }
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

sub process_deleteprocessormodel : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $id = $query->param('processormodel_id');
	eval {
		my $eprocessormodel = Entity::Processormodel->get(id => $id);
		$eprocessormodel->delete();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
	else { $self->redirect('/cgi/kanopya.cgi/models/view_models'); }
}

# motherboard model

sub form_addmotherboardmodel : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('Models/form_addmotherboardmodel.tmpl');
	$tmpl->param($errors) if $errors;
	
	my @processormodels = Entity::Processormodel->getProcessormodels(hash => {});
	my $pmodels = [];
	foreach my $x (@processormodels){
		my $tmp = {
			processormodel_id => $x->getAttr( name => 'processormodel_id'),
		    processormodel_name => join(' ',$x->getAttr(name =>'processormodel_brand'),$x->getAttr(name => 'processormodel_name')),
		};
		push (@$pmodels, $tmp);
	}
	$tmpl->param('processormodels_list' => $pmodels);
	return $tmpl->output();
}

sub process_addmotherboardmodel : Runmode {
    my $self = shift;
    use CGI::Application::Plugin::ValidateRM (qw/check_rm/); 
    my ($results, $err_page) = $self->check_rm('form_addmotherboardmodel', '_addmotherboardmodel_profile');
    return $err_page if $err_page;
    
    my $query = $self->query();
    my $mothmodel = Entity::Motherboardmodel->new(
		motherboardmodel_brand => $query->param('brand'),
		motherboardmodel_name => $query->param('name'),
		motherboardmodel_chipset => $query->param('chipset'),
		motherboardmodel_processor_num => $query->param('procnum'),
		motherboardmodel_consumption => $query->param('consumption'),
		motherboardmodel_iface_num => $query->param('ifacenum'),
		motherboardmodel_ram_slot_num => $query->param('ramslotnum'),
		motherboardmodel_ram_max => $query->param('rammax'),
		processormodel_id => $query->param('processorid') ne '0' ? $query->param('processorid') : undef,
	);
    eval { $mothmodel->create(); };
    if($@) {
    	my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
	else { return $self->close_window(); }
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

sub process_deletemotherboardmodel : Runmode {
	my $self = shift;
	my $query = $self->query();
	my $id = $query->param('motherboardmodel_id');
	eval {
		my $emotherboardmodel = Entity::Motherboardmodel->get(id => $id);
		$emotherboardmodel->delete();
	};
	if($@) {
		my $exception = $@;
		if(Kanopya::Exception::Permission::Denied->caught()) {
			$self->{adm}->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
			$self->redirect('/cgi/kanopya.cgi/systemstatus/permission_denied');
		}
		else { $exception->rethrow(); }
	}
	else { $self->redirect('/cgi/kanopya.cgi/models/view_models'); }
}

1;
