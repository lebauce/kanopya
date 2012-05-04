package Models;

use Dancer ':syntax';

use Administrator;
use Entity::Hostmodel;
use Entity::Processormodel;

prefix '/infrastructures';

sub _models {
    
    my @eprocessormodels = Entity::Processormodel->getProcessormodels(hash => {});
    my @ehostmodels = Entity::Hostmodel->getHostmodels(hash => {});
    my $processormodels = [];
    my $hostmodels = [];
    
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
        $h->{pmodel_virt} = $p->getAttr(name => 'processormodel_virtsupport');
        my $methods = $p->getPerms();
        if($methods->{'update'}->{'granted'}) { $h->{can_update} = 1; }
        if($methods->{'remove'}->{'granted'}) { $h->{can_delete} = 1; }
        if($methods->{'setperm'}->{'granted'}) { $h->{can_setperm} = 1; }
                    
        push @$processormodels, $h;
    }
    
    for my $p (@ehostmodels) {
        my $h = {};
        $h->{mmodel_id} = $p->getAttr(name => 'hostmodel_id');
        $h->{mmodel_brand} = $p->getAttr(name => 'hostmodel_brand');
        $h->{mmodel_name} = $p->getAttr(name => 'hostmodel_name');
        $h->{mmodel_chipset} = $p->getAttr(name => 'hostmodel_chipset');
        $h->{mmodel_processornum} = $p->getAttr(name => 'hostmodel_processor_num');
        $h->{mmodel_consumption} = $p->getAttr(name => 'hostmodel_consumption');
        $h->{mmodel_ifacenum} = $p->getAttr(name => 'hostmodel_iface_num');
        $h->{mmodel_ramslotnum} = $p->getAttr(name => 'hostmodel_ram_slot_num');
        $h->{mmodel_rammax} = $p->getAttr(name => 'hostmodel_ram_max');
        #$h->{PROCID} = $p->getAttr(name => 'processormodel_id');
        my $methods = $p->getPerms();
        if($methods->{'update'}->{'granted'}) { $h->{can_update} = 1; }
        if($methods->{'remove'}->{'granted'}) { $h->{can_delete} = 1; }
        if($methods->{'setperm'}->{'granted'}) { $h->{can_setperm} = 1; }
            
        push @$hostmodels, $h;
    } 
    return ($hostmodels,$processormodels);
}

get '/models' => sub {
	my ($hostmodels,$processormodels) = _models();
	my $can_createprocessormodel;
	my $can_createhostmodel;

    my $methods = Entity::Processormodel->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_createprocessormodel = 1 }
    $methods = Entity::Hostmodel->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_createhostmodel = 1 }

	template 'models', {
		titlepage => 'Hardware - Models',
        can_createprocessormodel => $can_createprocessormodel,
		can_createhostmodel => $can_createhostmodel,
		processormodels => $processormodels,
		hostmodels => $hostmodels,
	};
};

get '/models/hosts/add' => sub {
    my @processormodels = Entity::Processormodel->getProcessormodels(hash => {});
    my $pmodels = [];
    foreach my $x (@processormodels){
        my $tmp = {
            processormodel_id => $x->getAttr( name => 'processormodel_id'),
            processormodel_name => join(' ',$x->getAttr(name =>'processormodel_brand'),$x->getAttr(name => 'processormodel_name')),
        };
        push (@$pmodels, $tmp);
    }
    template 'form_addhostmodel', {
        processormodels_list => $pmodels,
    }, { layout => '' };
};

post '/models/hosts/add' => sub {
    my $adm = Administrator->new;
    my $mothmodel = Entity::Hostmodel->new(
        hostmodel_brand         => params->{brand},
        hostmodel_name          => params->{name},
        hostmodel_chipset       => params->{chipset},
        hostmodel_processor_num => params->{procnum},
        hostmodel_consumption   => params->{consumption},
        hostmodel_iface_num     => params->{ifacenum},
        hostmodel_ram_slot_num  => params->{ramslotnum},
        hostmodel_ram_max       => params->{rammax},
        processormodel_id              => params->{processorid} ne '0' ? params->{processorid} : undef,
    );
    eval { $mothmodel->create(); };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/infrastructures/models'); }
};

get '/models/processors/add' => sub {
    template 'form_addprocessormodel', {}, { layout => ''};
};

post '/models/processors/add' => sub {
    my $adm = Administrator->new;
    my $procmodel = Entity::Processormodel->new(
        processormodel_brand       => params->{brand},
        processormodel_name        => params->{name},
        processormodel_core_num    => params->{coresnum},
        processormodel_clock_speed => params->{clockspeed},
        processormodel_l2_cache    => params->{l2cache},
        processormodel_max_tdp     => params->{tdp},
        processormodel_64bits      => params->{is64bits},
        processormodel_virtsupport => params->{virtsupport},
    );
    eval { $procmodel->create(); };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/infrastructures/models'); }
};

get '/models/hosts/:modelid/remove' => sub {
    my $adm = Administrator->new;
    my $id = params->{modelid};
    eval {
        my $ehostmodel = Entity::Hostmodel->get(id => $id);
        $ehostmodel->delete();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/infrastructures/models'); }
};

get '/models/processors/:modelid/remove' => sub {
    my $adm = Administrator->new;
    my $id = params->{modelid};
    eval {
        my $eprocessormodel = Entity::Processormodel->get(id => $id);
        $eprocessormodel->delete();
    };
    if($@) {
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { redirect('/infrastructures/models'); }
};

1;
