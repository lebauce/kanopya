package Models;

use Dancer ':syntax';

use Entity::Motherboardmodel;
use Entity::Processormodel;

sub _models {
    
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
        $h->{pmodel_virt} = $p->getAttr(name => 'processormodel_virtsupport');
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
    return ($motherboardmodels,$processormodels);
}

get '/models' => sub {
	my ($motherboardmodels,$processormodels) = _models();
	my $can_createprocessormodel;
	my $can_createmotherboardmodel;

    my $methods = Entity::Processormodel->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_createprocessormodel = 1 }
    $methods = Entity::Motherboardmodel->getPerms();
    if($methods->{'create'}->{'granted'}) { $can_createmotherboardmodel = 1 }

	template 'models', {
		titlepage => 'Hardware - Models',
        can_createprocessormodel => $can_createprocessormodel,
		can_createmotherboardmodel => $can_createmotherboardmodel,
		processormodels => $processormodels,
		motherboardmodels => $motherboardmodels,
	};
}
