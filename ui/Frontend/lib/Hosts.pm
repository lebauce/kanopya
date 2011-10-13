package Hosts;

use Dancer ':syntax';

use Administrator;
use Entity::Motherboard;
use Entity::Kernel;
use Entity::Cluster;
use Entity::Processormodel;
use Entity::Motherboardmodel;
use Entity::Powersupplycard;
use Log::Log4perl "get_logger";

my $log = get_logger("webui");

prefix '/infrastructures';

sub _timestamp_format {
    my %args = @_;
    
    return 'unk' if (not defined $args{timestamp});
    
    my $period = time() - $args{timestamp};
   	my @time = (int($period/3600), int(($period % 3600) / 60), $period % 60);
    my $time_str = "";
    $time_str .= $time[0] . "h" if ($time[0] > 0);
    $time_str .= $time[1] . "m" if ($time[0] > 0 || $time[1] > 0);
    $time_str .= $time[2] . "s"; 
    
    return $time_str;
}

sub _hosts {
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
        $tmp->{motherboard_ip} = $m->getInternalIP()->{ipv4_internal_address};
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
    return $motherboards;
}

get '/hosts' => sub {
    my $methods = Entity::Motherboard->getPerms();
    template 'hosts', {
        motherboards_list => _hosts(),
        can_create        => $methods->{'create'}->{'granted'}
    };
};

get '/hosts/add' => sub {
    my @motherboardmodels = Entity::Motherboardmodel->getMotherboardmodels(hash => {});
    my @processormodels = Entity::Processormodel->getProcessormodels(hash => {});
    my @kernel = Entity::Kernel->getKernels(hash => {});
    my @powersupplycards = Entity::Powersupplycard->getPowerSupplyCards(hash => {});
    
    my $mmodels = [];
    foreach my $x (@motherboardmodels){
        my $tmp = {
            id => $x->getAttr( name => 'motherboardmodel_id'),
            name => join(' ',$x->getAttr(name =>'motherboardmodel_brand'),$x->getAttr(name => 'motherboardmodel_name')),
        };
        push (@$mmodels, $tmp);
    }
    
    my $pmodels = [];
    foreach my $x (@processormodels){
        my $tmp = {
            id => $x->getAttr( name => 'processormodel_id'),
            name => join(' ',$x->getAttr(name =>'processormodel_brand'),$x->getAttr(name => 'processormodel_name')),
        };
        push (@$pmodels, $tmp);
    }
    
    my $kernels = [];
    foreach my $x (@kernel){
        my $tmp = {
            id => $x->getAttr( name => 'kernel_id'),
            name => $x->getAttr(name => 'kernel_version'),
        };
        push (@$kernels, $tmp);
    }
    
    my $pscards = [];
    foreach my $x (@powersupplycards){
        my $tmp = {
            id => $x->getAttr( name => 'powersupplycard_id'),
            name => $x->getAttr(name => 'powersupplycard_name'),
        };
        push (@$pscards, $tmp);
    }
    
    template 'form_addmotherboard', {
        motherboardmodels_list => $mmodels,
        processormodels_list   => $pmodels,
        kernels_list           => $kernels,
        powersupplycards_list  => $pscards,
    };
};

post '/hosts/add' => sub {
    my $adm = Administrator->new;
    my %parameters = (
        motherboard_mac_address   => params->{mac_address}, 
        kernel_id                 => params->{kernel},  
        motherboard_serial_number => params->{serial_number}, 
        motherboardmodel_id       => params->{motherboard_model}, 
        processormodel_id         => params->{cpu_model}, 
        motherboard_desc          => params->{desc},
    );
    if(params->{powersupplycard_id} ne "none") {
        $parameters{powersupplycard_id}     = params->{powersupplycard_id};
        $parameters{powersupplyport_number} = params->{powersupplyport_number};
    }
    my $motherboard = Entity::Motherboard->new(%parameters);     
    eval { $motherboard->create() };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    }
    else { 
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'host creation adding to execution queue');
        redirect '/infrastructures/hosts'; 
    }
};

get '/hosts/:hostid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $motherboard = Entity::Motherboard->get(id => param('hostid'));
        $motherboard->remove();
    };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    } 
    else { redirect '/infrastructures/hosts'; }
};

get '/hosts/:hostid/activate' => sub {
    my $adm = Administrator->new;
    eval {
        my $motherboard = Entity::Motherboard->get(id => params->{hostid});
         $motherboard->activate();
    };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    } 
    else { 
        $adm->addMessage(from => 'Administrator', level => 'info', content => 'host activation adding to execution queue');
        redirect '/infrastructures/hosts/'.param('hostid'); 
    }
};

get '/hosts/:hostid/deactivate' => sub {
    my $adm = Administrator->new;
    eval {
        my $motherboard = Entity::Motherboard->get(id => param('hostid'));
         $motherboard->deactivate();
    };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    } 
    else { redirect '/infrastructures/hosts/'.param('hostid'); }
};

get '/hosts/:hostid/addharddisk' => sub {
    template 'form_addharddisk', {
        host_id => param('hostid')
    };
};

post '/hosts/:hostid/addharddisk' => sub {
    my $adm = Administrator->new;
    eval { 
        my $motherboard = Entity::Motherboard->get(id => param('hostid'));
        $motherboard->addHarddisk(device => param('device')); 
    };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    } else { redirect '/infrastructures/hosts/'.param('hostid'); }
};

get '/hosts/:hostid/removeharddisk/:harddiskid' => sub {
    my $adm = Administrator->new;
    eval { 
        my $motherboard = Entity::Motherboard->get(id => param('hostid'));
        $motherboard->removeHarddisk(harddisk_id => param('harddiskid')); 
    };
    if($@) { 
        my $exception = $@;
        if(Kanopya::Exception::Permission::Denied->caught()) {
            $adm->addMessage(from => 'Administrator', level => 'error', content => $exception->error);
            redirect '/permission_denied';
        }
        else { $exception->rethrow(); }
    } 
    else { redirect '/infrastructures/hosts/'.param('hostid'); }
};

get '/hosts/:hostid' => sub {
    my $motherboard_model;
    my $processor_model;
    my $motherboard_kernel;
    my $active;
    my $cluster_name;
    my $motherboard_state;
    my $timestamp;
    
    my $emotherboard = Entity::Motherboard->get(id => param('hostid'));
    my $methods = $emotherboard->getPerms();

    # motherboard model    
    my $mmodel_id = $emotherboard->getAttr(name => 'motherboardmodel_id');
    if($mmodel_id) {
        eval {
            my $emmodel = Entity::Motherboardmodel->get(id => $mmodel_id);
            $motherboard_model = $emmodel->getAttr(name =>'motherboardmodel_brand')." ".$emmodel->getAttr(name => 'motherboardmodel_name');
        };
    }
    else { $motherboard_model = 'not defined'; }

    # processor model
    my $pmodel_id = $emotherboard->getAttr(name => 'processormodel_id');
    if($pmodel_id) {    
        eval {
            my $epmodel = Entity::Processormodel->get(id => $pmodel_id);
            $processor_model = $epmodel->getAttr(name =>'processormodel_brand')." ".$epmodel->getAttr(name => 'processormodel_name');
        };
    } 
    else { $processor_model = 'not defined'; }

    # kernel
    eval {
        my $ekernel = Entity::Kernel->get(id => $emotherboard->getAttr(name => 'kernel_id'));
        $motherboard_kernel = $ekernel->getAttr('name' => 'kernel_name');
    };

    # state
    if($emotherboard->getAttr('name' => 'active')) {
        $active = 1;
        ($motherboard_state, $timestamp) = split ':', $emotherboard->getAttr('name' => 'motherboard_state');
        if($motherboard_state =~ /up|starting/) {
            eval {
                my $ecluster = Entity::Cluster->get(id => $emotherboard->getClusterId());
                $cluster_name = $ecluster->getAttr('name' => 'cluster_name');
            };
        } 
    } else {
        $active = 0;
        $motherboard_state = 'down';
    }
    
    # harddisks list
    my $harddisks = $emotherboard->getHarddisks();
    my $hds= [];
    foreach my $hd (@$harddisks) {
        my $tmp = {};
        $tmp->{harddisk_id}     = $hd->{harddisk_id};
        $tmp->{harddisk_device} = $hd->{harddisk_device}; 
        $tmp->{motherboard_id}  = $emotherboard->getAttr(name => 'motherboard_id');
                    
        if((not $methods->{'removeHarddisk'}->{'granted'}) || $active) {
            $tmp->{link_removeharddisk} = 0;
        } else { $tmp->{link_removeharddisk} = 1;}
        push @$hds, $tmp;
    }
   
    template 'hosts_details', {
        motherboard_id          => $emotherboard->getAttr('name' => 'motherboard_id'),
        motherboard_hostname    => $emotherboard->getAttr('name' => 'motherboard_hostname'),
        motherboard_desc        => $emotherboard->getAttr('name' => 'motherboard_desc'),
        motherboard_mac         => $emotherboard->getAttr('name' => 'motherboard_mac_address'),
        motherboard_ip          => $emotherboard->getInternalIP()->{ipv4_internal_address},
        motherboard_sn          => $emotherboard->getAttr('name' => 'motherboard_serial_number'),
        motherboard_powersupply => $emotherboard->getAttr('name' => 'motherboard_powersupply_id'),
        motherboard_model       => $motherboard_model,
        processor_model         => $processor_model,
        motherboard_kernel      => $motherboard_kernel,
        motherboard_state       => $motherboard_state,
        state_time              => _timestamp_format('timestamp' => $timestamp),
        nbharddisks             => scalar(@$hds)+1,
        harddisks_list          => $hds,
        active                  => $active,
        can_deactivate          => $methods->{'deactivate'}->{'granted'} && $active && $motherboard_state =~ /down/,
        can_delete              => $methods->{'remove'}->{'granted'} && !$active,
        can_activate            => $methods->{'activate'}->{'granted'} && !$active,
        can_setperm             => $methods->{'setperm'}->{'granted'},
        can_addHarddisk         => $methods->{'addHarddisk'}->{'granted'} && !$active,
    };
};



1;
