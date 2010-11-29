package Mcsui::Models;
use base 'CGI::Application';
use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::Redirect;
use strict;
use warnings;

my $closewindow = "<script type=\"text/javascript\">window.opener.location.reload();window.close();</script>";

sub setup {
	my $self = shift;
	my $tmpl_path = [
		'/workspace/mcs/UI/web/Mcsui/templates',
		'/workspace/mcs/UI/web/Mcsui/templates/Models'];
	$self->tmpl_path($tmpl_path);
	$self->{'admin'} = Administrator->new(login => 'thom', password => 'pass');
}

# models listing

sub view_models : StartRunmode {
    my $self = shift;
    my $tmpl = $self->load_tmpl('view_models.tmpl');
    $tmpl->param('titlepage' => "Hardaware - Models");
	$tmpl->param('mHardware' => 1);
	$tmpl->param('submModels' => 1);
    
    my @eprocessormodels = $self->{admin}->getEntities(type => 'Processormodel', hash => {});
    my @emotherboardmodels = $self->{admin}->getEntities(type => 'Motherboardmodel', hash => {});
    my $processormodels = [];
    my $motherboardmodels = [];
    
    for my $p (@eprocessormodels) {
		my $h = {};
		#$h->{ID} = $p->getAttr(name => 'processormodel_id');
		$h->{pmodel_brand} = $p->getAttr(name => 'processormodel_brand');
		$h->{pmodel_name} = $p->getAttr(name => 'processormodel_name');
		$h->{pmodel_corenum} = $p->getAttr(name => 'processormodel_core_num');
		$h->{pmodel_clockspeed} = $p->getAttr(name => 'processormodel_clock_speed');
		$h->{pmodel_l2cache} = $p->getAttr(name => 'processormodel_l2_cache');
		$h->{pmodel_tdp} = $p->getAttr(name => 'processormodel_max_tdp');
		$h->{pmodel_is64} = $p->getAttr(name => 'processormodel_64bits');
					
		push @$processormodels, $h;
	}
    
    for my $p (@emotherboardmodels) {
		my $h = {};
		#$h->{ID} = $p->getAttr(name => 'motherboardmodel_id');
		$h->{mmodel_brand} = $p->getAttr(name => 'motherboardmodel_brand');
		$h->{mmodel_name} = $p->getAttr(name => 'motherboardmodel_name');
		$h->{mmodel_chipset} = $p->getAttr(name => 'motherboardmodel_chipset');
		$h->{mmodel_processornum} = $p->getAttr(name => 'motherboardmodel_processor_num');
		$h->{mmodel_consumption} = $p->getAttr(name => 'motherboardmodel_consumption');
		$h->{mmodel_ifacenum} = $p->getAttr(name => 'motherboardmodel_iface_num');
		$h->{mmodel_ramslotnum} = $p->getAttr(name => 'motherboardmodel_ram_slot_num');
		$h->{mmodel_rammax} = $p->getAttr(name => 'motherboardmodel_ram_max');
		#$h->{PROCID} = $p->getAttr(name => 'processormodel_id');
			
		push @$motherboardmodels, $h;
	} 
	$tmpl->param('processormodels_list' => $processormodels);
	$tmpl->param('motherboardmodels_list' => $motherboardmodels);
		    
    return $tmpl->output();
}

# processor model 

sub form_addprocessormodel : Runmode {
    my $self = shift;
    my $errors = shift;
    my $tmpl =  $self->load_tmpl('form_addprocessormodel.tmpl');
    $tmpl->param($errors) if $errors;
	
	return $tmpl->output();
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
    return  $closewindow;
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
    my $tmpl =  $self->load_tmpl('form_addmotherboardmodel.tmpl');
	$tmpl->param($errors) if $errors;
	
	my @processormodels = $self->{'admin'}->getEntities(type => 'Processormodel', hash => {});
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
    return  $closewindow;
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
