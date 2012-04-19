package Vms;

use Dancer ':syntax';

use Administrator;
use Entity::Host;
use Entity::Kernel;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Processormodel;
use Entity::Hostmodel;
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

sub _vms {
    my @ehosts = Entity::Host->getHosts(hash => {cloud_cluster_id => { '!=', undef }});
    my $hosts = [];

    foreach my $m (@ehosts) {
        my $tmp = {};
        $tmp->{link_activity} = 0;
        $tmp->{state_up} = 0;
        $tmp->{state_down} = 0;
        $tmp->{state_starting} = 0;
        $tmp->{state_stopping} =0;
        $tmp->{state_broken} = 0;

        $tmp->{host_id} = $m->getAttr(name => 'host_id');

        $tmp->{host_label} = $m->toString();
        my $state = $m->getAttr(name => 'host_state');
        $tmp->{host_hostname} = $m->getAttr(name => 'host_hostname');
        $tmp->{host_ip} = $m->getInternalIP()->{ipv4_internal_address};
        $tmp->{active} = $m->getAttr(name => 'active');
        $tmp->{cloud_cluster_id} = $m->getAttr(name => 'cloud_cluster_id');

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

        $tmp->{host_desc} = $m->getAttr(name => 'host_desc');
        push (@$hosts, $tmp);
    }
    return $hosts;
}

get '/vms' => sub {
    my $methods = Entity::Host->getPerms();
    template 'vms', {
        vms_list => _vms(),
        can_create        => $methods->{'create'}->{'granted'}
    };
};

get '/vms/add' => sub {
    my @hostmodels = Entity::Hostmodel->getHostmodels(hash => {});
    my @processormodels = Entity::Processormodel->getProcessormodels(hash => {});
    my @kernel = Entity::Kernel->getKernels(hash => {});
    my @powersupplycards = Entity::Powersupplycard->getPowerSupplyCards(hash => {});

    my $mmodels = [];
    foreach my $x (@hostmodels){
        my $tmp = {
            id => $x->getAttr( name => 'hostmodel_id'),
            name => join(' ',$x->getAttr(name =>'hostmodel_brand'),$x->getAttr(name => 'hostmodel_name')),
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

    template 'form_addhost', {
        hostmodels_list => $mmodels,
        processormodels_list   => $pmodels,
        kernels_list           => $kernels,
        powersupplycards_list  => $pscards,
    }, { layout => '' };
};

post '/vms/add' => sub {
    my $adm = Administrator->new;
    my %parameters = (
        kernel_id                 => params->{kernel},
        host_serial_number => params->{serial_number},
	host_ram           => params->{ram},
	host_core          => params->{core},
        hostmodel_id       => params->{host_model},
        processormodel_id         => params->{cpu_model},
        host_desc          => params->{desc},
    );
    if(params->{powersupplycard_id} ne "none") {
        $parameters{powersupplycard_id}     = params->{powersupplycard_id};
        $parameters{powersupplyport_number} = params->{powersupplyport_number};
    }
    my $host = Entity::Host->new(%parameters);
    eval { $host->create() };
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

get '/vms/:hostid/remove' => sub {
    my $adm = Administrator->new;
    eval {
        my $host = Entity::Host->get(id => param('hostid'));
        $host->remove();
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

get '/vms/:hostid/activate' => sub {
    my $adm = Administrator->new;
    eval {
        my $host = Entity::Host->get(id => params->{hostid});
         $host->activate();
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

get '/vms/:hostid/deactivate' => sub {
    my $adm = Administrator->new;
    eval {
        my $host = Entity::Host->get(id => param('hostid'));
         $host->deactivate();
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

get '/vms/migrate/:host_id' => sub {
    

    my $hypervisors = [];
    my $host = Entity::Host->get(id => params->{'host_id'});
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => $host->getAttr(name => 'cloud_cluster_id'));
    my $opennebula = $cluster->getComponent(name => 'opennebula', version => 3);
    my $hypervisors_r = $opennebula->{_dbix}->opennebula3->opennebula3_hypervisors->search({});
    $log->info('<<<<<<<<<<'.ref($hypervisors_r));
    while (my $row = $hypervisors_r->next) {
	$log->info('<<<<<<<<'.$row->get_column('hypervisor_id'));
	my $h = Entity::Host->get(id => $row->get_column('hypervisor_host_id'));
	my $tmp = {
	    hypervisor_id => $row->get_column('hypervisor_host_id'),
	    hypervisor_hostname => $h->getAttr(name => 'host_hostname'),
	};
	push @$hypervisors, $tmp;
    }

    template 'form_migratevm',  {
	host_id => params->{'host_id'},
	hypervisor_list => $hypervisors,    
    }, { layout => '' };
};

post '/vms/migrate' => sub {
    
    #my $dest = 

    Operation->enqueue(
	type => 'MigrateHost',
	priority => 1,
	params => {
	    host_id => params->{host_id},
	    hypervisor_dst => params->{hypervisors}
	}
   ); 
redirect '/infrastructures/vms';
};

#************************************************************************************************************************************
get '/vms/scale_memory/:host_id' => sub {
    

    

    template 'form_scalememory',  {
	host_id => params->{'host_id'},   
    }, { layout => '' };
};

post '/vms/scale_memory' => sub {
    
   

    Operation->enqueue(
	type => 'ScalememoryHost',
	priority => 1,
	params => {
	    host_id => params->{host_id},
	    memory_quantity => params->{memory_quantity}
	}
   ); 
redirect '/infrastructures/vms';
};

get '/vms/scale_cpu/:host_id' => sub {
    

    

    template 'form_scalecpu',  {
	host_id => params->{'host_id'},   
    }, { layout => '' };
};

post '/vms/scale_cpu' => sub {
    
   

    Operation->enqueue(
	type => 'ScalecpuHost',
	priority => 1,
	params => {
	    host_id => params->{host_id},
	    memory_quantity => params->{vcpu_number}
	}
   ); 
redirect '/infrastructures/vms';
};

#************************************************************************************************************************************

get '/vms/:hostid/addharddisk' => sub {
    template 'form_addharddisk', {
        host_id => param('hostid')
    }, { layout => '' };
};

post '/vms/:hostid/addharddisk' => sub {
    my $adm = Administrator->new;
    eval {
        my $host = Entity::Host->get(id => param('hostid'));
        $host->addHarddisk(device => param('device'));
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

get '/vms/:hostid/removeharddisk/:harddiskid' => sub {
    my $adm = Administrator->new;
    eval {
        my $host = Entity::Host->get(id => param('hostid'));
        $host->removeHarddisk(harddisk_id => param('harddiskid'));
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

get '/vms/:hostid' => sub {
    my $host_model;
    my $processor_model;
    my $host_kernel;
    my $active;
    my $cluster_name;
    my $host_state;
    my $timestamp;

    my $ehost = Entity::Host->get(id => param('hostid'));
    my $methods = $ehost->getPerms();

    # host model
    my $mmodel_id = $ehost->getAttr(name => 'hostmodel_id');
    if($mmodel_id) {
        eval {
            my $emmodel = Entity::Hostmodel->get(id => $mmodel_id);
            $host_model = $emmodel->getAttr(name =>'hostmodel_brand')." ".$emmodel->getAttr(name => 'hostmodel_name');
        };
    }
    else { $host_model = 'not defined'; }

    # processor model
    my $pmodel_id = $ehost->getAttr(name => 'processormodel_id');
    if($pmodel_id) {
        eval {
            my $epmodel = Entity::Processormodel->get(id => $pmodel_id);
            $processor_model = $epmodel->getAttr(name =>'processormodel_brand')." ".$epmodel->getAttr(name => 'processormodel_name');
        };
    }
    else { $processor_model = 'not defined'; }

    # kernel
    eval {
        my $ekernel = Entity::Kernel->get(id => $ehost->getAttr(name => 'kernel_id'));
        $host_kernel = $ekernel->getAttr('name' => 'kernel_name');
    };

    # state
    if($ehost->getAttr('name' => 'active')) {
        $active = 1;
        ($host_state, $timestamp) = split ':', $ehost->getAttr('name' => 'host_state');
        if($host_state =~ /up|starting/) {
            eval {
                my $ecluster = Entity::ServiceProvider::Inside::Cluster->get(id => $ehost->getClusterId());
                $cluster_name = $ecluster->getAttr('name' => 'cluster_name');
            };
        }
    } else {
        $active = 0;
        $host_state = 'down';
    }

    # harddisks list
    my $harddisks = $ehost->getHarddisks();
    my $hds= [];
    foreach my $hd (@$harddisks) {
        my $tmp = {};
        $tmp->{harddisk_id}     = $hd->{harddisk_id};
        $tmp->{harddisk_device} = $hd->{harddisk_device};
        $tmp->{host_id}  = $ehost->getAttr(name => 'host_id');

        if((not $methods->{'removeHarddisk'}->{'granted'}) || $active) {
            $tmp->{link_removeharddisk} = 0;
        } else { $tmp->{link_removeharddisk} = 1;}
        push @$hds, $tmp;
    }

    template 'hosts_details', {
        host_id          => $ehost->getAttr('name' => 'host_id'),
        host_hostname    => $ehost->getAttr('name' => 'host_hostname'),
        host_desc        => $ehost->getAttr('name' => 'host_desc'),
        host_ip          => $ehost->getInternalIP()->{ipv4_internal_address},
        host_sn          => $ehost->getAttr('name' => 'host_serial_number'),
        host_powersupply => $ehost->getAttr('name' => 'host_powersupply_id'),
        host_model       => $host_model,
        processor_model         => $processor_model,
        host_kernel      => $host_kernel,
        host_state       => $host_state,
        state_time              => _timestamp_format('timestamp' => $timestamp),
        nbharddisks             => scalar(@$hds)+1,
        harddisks_list          => $hds,
        active                  => $active,
        can_deactivate          => $methods->{'deactivate'}->{'granted'} && $active && $host_state =~ /down/,
        can_delete              => $methods->{'remove'}->{'granted'} && !$active,
        can_activate            => $methods->{'activate'}->{'granted'} && !$active,
        can_setperm             => $methods->{'setperm'}->{'granted'},
        can_addHarddisk         => $methods->{'addHarddisk'}->{'granted'} && !$active,
    };
};

1;
