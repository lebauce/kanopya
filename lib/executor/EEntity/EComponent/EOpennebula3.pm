#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
package EEntity::EComponent::EOpennebula3;
use base "EEntity::EComponent";
use base "EManager::EHostManager::EVirtualMachineManager";

use strict;
use warnings;

use Entity;
use Entity::ContainerAccess;
use EFactory;
use General;
use CapacityManagement;
use XML::Simple;
use Log::Log4perl "get_logger";
use Data::Dumper;
use NetAddr::IP;
use File::Copy;
use Hash::Merge qw(merge);

my $log = get_logger("");
my $errmsg;

###############################
# component interface methods #
###############################

sub addNode {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'host', 'mount_point', 'cluster' ]
    );

    $self->configureNode(%args);
}

# generate configuration files on node
sub configureNode {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['cluster', 'host', 'mount_point']
    );

    my $masternodeip = $args{cluster}->getMasterNodeIp();
    my $hypervisor_type = $self->getHypervisorType();

    if(not $masternodeip) {
        # we start the first node so we start opennebula services
        $log->debug('opennebula frontend configuration');
        $log->debug('generate /etc/one/oned.conf');

        $self->_generateOnedConf(%args);

        $self->addInitScripts(
                mountpoint => $args{mount_point},
                scriptname => 'opennebula',
        );

        $self->addInitScripts(
                mountpoint => $args{mount_point},
                scriptname => 'nfs-kernel-server',
        );

        my $admin = $args{host}->getAdminIface();
        my $network = NetAddr::IP->new(
            $admin->getIPAddr(),
            $admin->getPoolip()->poolip_netmask,
        )->network();
    }

    # configure kvm hypervisor
    if ($hypervisor_type eq 'kvm') {
        $log->debug('generate /lib/udev/rules.d/60-qemu-kvm.rules');
        $self->_generateQemuKvmUdev(%args);

        $self->addInitScripts(
          mountpoint => $args{mount_point},
          scriptname => 'libvirt-bin',
        );

        $self->addInitScripts(
              mountpoint => $args{mount_point},
              scriptname => 'qemu-kvm',
        );
    # configure xen hypervisor
    } elsif($hypervisor_type eq 'xen') {
        $log->debug('generate /etc/xen/xend-config.sxp');
        $self->_generateXenconf(%args);

        $self->addInitScripts(
              mountpoint => $args{mount_point},
              scriptname => 'xend',
        );

        $self->addInitScripts(
              mountpoint => $args{mount_point},
              scriptname => 'xendomains',
        );
    }
    # create directories for registered datastores
    my $conf = $self->getConf();
    for my $repo (@{$conf->{opennebula3_repositories}}) {
        if(defined $repo->{datastore_id}) {
            my $dir = $args{mount_point}.'/var/lib/one/datastores/'.$repo->{datastore_id};
            my $cmd = "mkdir -p $dir";
            $self->getExecutorEContext->execute(command => $cmd);
        }
    }
}

sub postStartNode {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

    # if the host is the opennebula master, we register datastores
    if($args{cluster}->getMasterNodeIp() eq $args{host}->getAdminIp()) {
        my $conf = $self->getConf();
        my $comp = $self->_getEntity();
        my $linux0 = $args{cluster}->getComponent(name => "Linux", version => "0");
        my $oldconf = $linux0->getConf();
        my @mountentries = @{$oldconf->{linux0s_mount}};

        for my $repo (@{$conf->{opennebula3_repositories}}) {
            if(not defined $repo->{datastore_id}) {
                # declare the datastore
                my $ds_name = $repo->{repository_name};
                my $ds_template = $self->generateDatastoreTemplate(ds_name => $ds_name);
                my $dsid = $self->onedatastore_create(file => $ds_template);

                # update the datastore id in db
                $comp->{_dbix}->opennebula3_repositories->search(
                    {repository_name => $ds_name}
                )->single->update({datastore_id => $dsid});

                # create the directory and mount the container
                my $command = one_command("mkdir -p /var/lib/one/datastores/$dsid");
                $self->getEContext->execute(command => $command);
                my $container_access = Entity::ContainerAccess->get(
                                       id => $repo->{container_access_id}
                                   );
                $command = 'mount -t nfs -o rw,sync,vers=3 ';
                $command .= $container_access->getAttr(name => 'container_access_export');
                $command .= " /var/lib/one/datastores/$dsid";
                $self->getEContext->execute(command => $command);

                # update linux0 mount table
                push @mountentries, {
                    linux0_mount_dumpfreq   => 0,
                    linux0_mount_filesystem => 'nfs',
                    linux0_mount_point      => "/var/lib/one/datastores/$dsid",
                    linux0_mount_device     => $container_access->getAttr(name => 'container_access_export'),
                    linux0_mount_options    => 'rw,sync,vers=3',
                    linux0_mount_passnum    => 0,
                };
            }
        }
        $linux0->setConf(conf => { linux0s_mount => \@mountentries});
    }

    # hypervisor declaration
    my $hostname = $args{host}->getAttr(name => 'host_hostname');
    my $hostid = $self->onehost_create(hostname => $hostname);

    # Delete the hypervisor from opennebula if the operation fail later.
    if (exists $args{erollback} and defined $args{erollback}){
        $args{erollback}->add(
            function   => $self->can('onehost_delete'),
            parameters => [ $self, 'host_nameorid', $hostid ]
        );
    }

    $log->info('Hypervisor id returned by opennebula: ' . $hostid);
    my $hypervisor = $self->addHypervisor(
        host       => $args{host}->_getEntity,
        onehost_id => $hostid
    );

    $self->onehost_enable(host_nameorid => $hostname);

}

sub preStopNode {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

     $self->onehost_delete(host_nameorid => $args{host}->onehost_id);
     # TODO verifier le succes de la commande

     $self->_getEntity->removeHypervisor(host => $args{host});
}

# Execute host migration to a new hypervisor
sub migrateHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ 'host', 'hypervisor_dst', 'hypervisor_cluster']);

    # instanciate opennebula master node econtext
    my $masternodeip = $args{hypervisor_cluster}->getMasterNodeIp();
    my $masternode_econtext = EFactory::newEContext(ip_source      => $self->getExecutorEContext->getLocalIp,
                                                    ip_destination => $masternodeip);

    # Get the source hypervisor
    my $src_hypervisor = $args{host}->hypervisor;
    $log->debug("The VM <" . $args{host}->getId . "> is on the <" . $src_hypervisor->getId . "> host");

    my $hypervisor_id = $args{hypervisor_dst}->onehost_id;
    my $hypervisor_host_name = $args{hypervisor_dst}->getAttr(name=>'host_hostname');

    my $host_id = $args{host}->onevm_id;

    $log->debug("Apply VLAN on the destination hypervisor");
    $self->propagateVLAN(host       => $args{host},
                         hypervisor => $args{hypervisor_dst});

    $self->onevm_livemigrate(
        vm_nameorid   => $host_id,
        host_nameorid => $hypervisor_id
    );

    return $src_hypervisor;
}


sub getVMState {
    my ($self,%args) = @_;
    General::checkParams(args     => \%args, required => ['host']);

    my $host_id = $args{host}->onevm_id;
    my $hxml = $self->onevm_show(vm_nameorid => $host_id);

    my $history = $hxml->{HISTORY_RECORDS}->{HISTORY};
    my $hypervisor_migr;

    if (ref $history eq 'HASH') {
        $hypervisor_migr = $history->{HOSTNAME};
    }
    elsif (ref $history eq 'ARRAY')  {
        $hypervisor_migr =  $history->[-1]->{HOSTNAME};
    }
    # Else $hypervisor_migr stay undef

    my $state_id     = $hxml->{STATE};
    my $lcm_state_id = $hxml->{LCM_STATE};

    my $state = {
         0 => { 0 => 'init' },
         1 => { 0 => 'pend' },
         2 => { 0 => 'hold' },
         3 => { 1 => 'prog', 2 => 'boot', 3 => 'runn', 4 => 'migr', 5 => 'save',
                6 => 'save', 7 => 'save', 8 => 'migr', 9 => '',    10 => 'epil',
               11 => 'epil', 12 => 'shut', 13 => 'shut'},
         4 => { 0 => 'stop' },
         5 => { 0 => 'suspended' },
         6 => { 0 => 'done' },
         7 => { 0 => 'fail' },
    };

    $log->info("<$state_id> <$lcm_state_id> => <".($state->{$state_id}->{$lcm_state_id}).'>');
    return { state => $state->{$state_id}->{$lcm_state_id}, hypervisor => $hypervisor_migr };

}

# execute memory scale in
sub scale_memory {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'memory' ]);

    my $host_id = $args{host}->onevm_id;

    $self->onevm_memset(vm_nameorid => $host_id, ram => $args{memory} / 1024 / 1024);
}

sub restoreHost {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'hypervisor' ],
                         optional => { check_resubmit   => undef,
                                       check_hypervisor => undef,
                                       check_resources  => undef });

    my $host_name = $args{hypervisor}->host_hostname;
    my $vms       = $args{hypervisor}->getVms();

    if (defined $args{check_resubmit} || defined $args{check_hypervisor}) {
        for my $vm (@{$vms}) {
            my $state = $self->getVMState(host => $vm );

            $log->info('vm <'.($vm->getId).'> hv '.$state->{hypervisor}.' state '.$state->{state});
            if($state->{state} eq 'runn') {
                if (defined $args{hypervisor}) {
                    if(!($args{hypervisor}->host_hostname eq $state->{hypervisor})){
                        $log->info('VM running on a wrong hypervisor');
                        $vm->setAttr(name => 'hypervisor_id', value => Entity::Host->find(hash => {host_hostname => $state->{hypervisor}})->getId());
                        $vm->save();
                    }
                }
            }
            else{
                if(defined $args{check_resubmit}){
                    $self->onevm_resubmit(vm_nameorid => $vm->onevm_id);
                }
            }
        }
    }

    if (defined $args{check_resources}) {
        my $host_vm_capacities = $args{hypervisor}->getVmResources();

        $log->info(Dumper $host_vm_capacities);

        for my $vm (@{$vms}) {
            $log->info('VM <'.($vm->getId()).'> <'.($vm->host_hostname).'>');

            if(defined $host_vm_capacities->{$vm->getId()}->{ram}) {

                if ( (not defined $vm->host_ram)
                     || $host_vm_capacities->{$vm->getId()}->{ram} != $vm->host_ram) {
                        $log->info('Memory one = '.($host_vm_capacities->{$vm->getId()}->{ram}).' VS db = '.($vm->host_ram));
                        $vm->updateMemory(memory => $host_vm_capacities->{$vm->getId()}->{ram});
                }
            }
            else {
                $log->info('No RAM value from opennebula for this VM, try to check hypervisor or resubmit it');
            }

            if(defined $host_vm_capacities->{$vm->getId()}->{ram}) {
                if( (not defined $vm->host_core)
                    || $host_vm_capacities->{$vm->getId()}->{cpu} != $vm->host_core){
                    $log->info('Cpu one = '.(($host_vm_capacities->{$vm->getId()}->{cpu})).' VS db = '.($vm->host_core));
                    $vm->updateCPU(cpu_number => $host_vm_capacities->{$vm->getId()}->{cpu});
                }
            }
            else {
                $log->info('No CPU value from opennebula for this VM, try to check hypervisor or resubmit it');
            }
       }
    }
}

#execute cpu scale in
sub scale_cpu {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cpu_number' ]);

    my $cpu_number = $args{cpu_number};

    my $host_id = $args{host}->onevm_id;
    my $hyptype = $self->getHypervisorType;
    if ($hyptype eq 'kvm') {
        if ($cpu_number <= $args{host}->opennebula3_kvm_vm_cores) {
            $args{host}->updateCpus(cpus => $cpu_number);
            return;
        }
        else {
            $args{host}->updateCpus;
            return;
        }
    }

    # This line is never called as the VM are created with the maximum
    # number of VCPUs and scaled down at startup due to a bug in libvirtd
    $self->onevm_vcpuset(vm_nameorid => $host_id, cpu => $cpu_number);
}



sub retrieveOpennebulaHypervisorStatus {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );

    my $hxml = $self->onehost_show(host_nameorid => $args{host}->host_hostname);
    if($hxml->{STATE} != 2) {
        $log->info('hypervisor <'.$args{host}->host_hostname.'> error for opennebula');
        return 0;
    }

    $log->info('hypervisor <'.$args{host}->host_hostname.'> running for opennebula');
    return 1;
}

sub isUp {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

    my $hostip = $args{host}->getAdminIp;
    my $masternodeip = $args{cluster}->getMasterNodeIp();

    if((defined $masternodeip) && ($masternodeip eq $hostip)) {
        # host is the opennebula frontend
        # we must test opennebula port reachability
        my $net_conf = $self->{_entity}->getNetConf();
        my ($port, $protocols) = each %$net_conf;
        my $cmd = "nmap -n -sT -p $port $hostip | grep $port | cut -d\" \" -f2";
        my $port_state = `$cmd`;
        chomp($port_state);
        $log->debug("Check host <$hostip> on port $port ($protocols->[0]) is <$port_state>");
        if ($port_state eq "closed"){
            return 0;
        }
    }

    return 1;
}

# generate vm template and start a vm from the template
sub startHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    if( !defined $args{hypervisor}){
        my $errmsg = "Cannot add node in cluster ".$args{host}->getClusterId().", no hypervisor available";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Pick up an hypervisor
    my $hypervisor_type = $self->getHypervisorType();
    my $hypervisor = $args{hypervisor};
    $log->info("Picked up hypervisor " . $hypervisor->getId());

    # generate image template for the vm and register it
    my $cluster = Entity->get(id => $args{host}->getClusterId());
    my $disk_params = $cluster->getManagerParameters(manager_type => 'disk_manager');
    my $image = $args{host}->getNodeSystemimage();
    my $image_name = $image->getAttr(name => 'systemimage_name');

    my %repo = $self->_getEntity()->getImageRepository(
                   container_access_id => $disk_params->{container_access_id}
               );

    my $image_templatefile = $self->generateImageTemplate(
        image_name        => $image_name,
        image_source      => $repo{datastore_id}.'/'.$image_name.'.img',
    );

    my $imageid = $self->oneimage_create(
        file               => $image_templatefile,
        datastore_nameorid => $repo{datastore_id}
    );

    # generate template in opennebula master node
    my $vm_templatefile;
    if ($hypervisor_type eq 'kvm') {
        $vm_templatefile = $self->generateKvmVmTemplate(
            host       => $args{host},
            hypervisor => $hypervisor,
        );
    } elsif ($hypervisor_type eq 'xen') {
        $vm_templatefile = $self->generateXenVmTemplate(
            host       => $args{host},
            hypervisor => $hypervisor,
        );
    }

    # Apply the VLAN's on the hypervisor interface dedicated to virtual machines
    $self->propagateVLAN(host       => $args{host},
                         hypervisor => $hypervisor);

    # create the vm from template
    my $vmid = $self->onevm_create(file => $vm_templatefile);

    # declare vm in database
    $log->info('vm id returned by opennebula: '.$vmid);

    # deploy the VM as the OpenNebula's scheduler sometimes refuse to deploy it
    my $cmd = one_command("onevm deploy " . $args{host}->host_hostname .
                          " " . $hypervisor->host_hostname);

    my $result = $self->getEContext->execute(command => $cmd);
    if ($result->{exitcode} != 0) {
       throw Kanopya::Exception::Execution(error => $result->{stdout});
    }

    $self->_getEntity()->addVM(
        host       => $args{host}->_getEntity,
        id         => $vmid,
        hypervisor => $hypervisor
    );

}

# delete a vm from opennebula
sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # retrieve vm info from opennebula

    my $id = $args{host}->onevm_id;
    my $image = $args{host}->getNodeSystemimage();

    my $xml = $self->onevm_show(vm_nameorid => $id);

    # delete the vm
    $self->onevm_delete(vm_nameorid => $id);

    # delete the vnets
    my @ifaces = $args{host}->getIfaces();
    for my $iface (@ifaces) {
        my $name = $xml->{NAME}.'-'.$iface->getAttr(name => 'iface_name');
        $self->onevnet_delete(vnet_nameorid => $name);
    }
    # delete the image
    my $name = $image->getAttr(name => 'systemimage_name');
    $self->oneimage_delete(image_nameorid => $name);

    # In the case of OpenNebula, we delete the host once it's stopped
    $args{host}->setAttr(name  => 'active',
                         value => '0');
    $args{host}->save;
    $args{host}->remove;
}

# update a vm information (hypervisor host and vnc port)
sub postStart {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    my $oneid = $args{host}->onevm_id;
    my $hxml    = $self->onevm_show(vm_nameorid => $oneid);

    my $vnc_port = $hxml->{TEMPLATE}->{GRAPHICS}->{PORT};

    # Check final RAM and CPU and store
    $args{host}->setAttr(name => 'vnc_port',  value => $vnc_port);
    $args{host}->save();

    if ($self->getHypervisorType() eq 'xen') {
        $args{host}->updateMemory(memory => $args{host}->getTotalMemory);
        $args{host}->updateCPU(cpu_number => $args{host}->getTotalCpu);

        $log->info('Set Ram and Cpu from real info : ram <' . $args{host}->host_ram .
                   '> cpu <' . $args{host}->host_core . '>');
    }
}

sub applyVLAN {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'iface', 'vlan' ]
    );

    # In the case of OpenNebula, we need to apply the VLAN on the
    # bridge interface of the hypervisor the VM is running on.
}

# Apply the VLAN's on the hypervisor interface dedicated to virtual machines

sub propagateVLAN {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'host', 'hypervisor' ]
    );

    my $bridge = ($args{hypervisor}->getIfaces(role => 'vms'))[0];
    for my $iface (@{$args{host}->getIfaces}) {
        for my $network ($iface->getInterface->getNetworks) {
            if ($network->isa("Entity::Network::Vlan")) {
                $log->info("Applying vlan " . $network->getAttr(name => "network_name") .
                           " on the bridge interface " . $iface->getAttr(name => "iface_name"));
                my $ehost_manager = EFactory::newEEntity(data => $args{hypervisor}->getHostManager);
                $ehost_manager->applyVLAN(iface => $bridge,
                                          vlan  => $network,
                                          delete => (defined ($args{delete}) && $args{delete}) ? 1 : 0);
            }
        }
    }
}

sub vmLoggedErrorMessage {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'opennebula3_vm' ]
    );

    my $command = one_command('tail -n 50 /var/log/one/oned.log |grep "LOG I '.($args{opennebula3_vm}->onevm_id).' Error"');

    $log->debug("commande = $command");
    my $result  = $self->getEContext->execute(command => $command);
    my $output  = $result->{stdout};
    $log->debug($output);

    my @lastmessage =  split '\n',$output;

    $log->debug(@lastmessage);
    return $lastmessage[-1];

}

sub forceDeploy {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'vm', 'hypervisor' ]
    );
    $self->onevm_deploy(
        vm_nameorid   => $args{vm}->onevm_id,
        host_nameorid => $args{hypervisor}->onehost_id
    );
}

#########################################
# configuration files generation methods #
#########################################

# generate /etc/oned.conf configuration file
sub _generateOnedConf {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'host', 'mount_point']
    );

    my $cluster = $self->_getEntity->getServiceProvider;
    my $data = $self->_getEntity()->getTemplateDataOned();
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/one/oned.conf',
        template_dir  => '/templates/components/opennebula',
        template_file => 'oned.conf.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/one'
    );
}

sub _generateQemuKvmUdev {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    my $command = "echo 'KERNEL==\"kvm\", OWNER==\"oneadmin\", GROUP==\"kvm\", MODE==\"0660\"' > $args{mount_point}/lib/udev/rules.d/60-qemu-kvm.rules";
    $self->getExecutorEContext->execute(command => $command);
}


# generate /etc/xen/xend-config.sxp configuration file
sub _generateXenconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    # TODO: Remove me
    my $data = {
        vmiface      => 'eth1',
        min_mem_dom0 => '1024'
    };

    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/xen/xend-config.sxp',
        template_dir  => '/templates/components/opennebula',
        template_file => 'xend-config.sxp.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/xen'
    );
}

###########################################
# opennebula templates generation methods #
###########################################

# generate datastore template and push it on opennebula master node
sub generateDatastoreTemplate {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['ds_name']
    );

    my $data = {
        datastore_name   => $args{ds_name},
        datastore_ds_mad => 'fs',
        datastore_tm_mad => 'shared',
    };

    my $cluster = $self->_getEntity->getServiceProvider;
    my $template_file = 'datastore-' . $args{ds_name} . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $cluster->getMasterNode,
        file          => $template_file,
        template_dir  => '/templates/components/opennebula',
        template_file => 'datastore.tt',
        data         => $data,
    );

    $self->getEContext->send(
        src  => $file,
        dest => '/tmp'
    );
    return '/tmp/' . $template_file;
}

# generate image template and push it on opennebula master node
# image_source is $datastore_id/$image_file.img
sub generateImageTemplate {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'image_name','image_source']
    );

    my $hypervisor_type = $self->getHypervisorType();
    my $data = {
        image_name        => $args{image_name},
        image_description => 'vm image',
        image_type        => 'OS',
        image_persistent  => 'YES',
        image_source      => $args{image_source},
        image_devprefix   => 'sd',
        image_disktype    => 'FILE'
    };

    if($hypervisor_type eq 'xen') {
        $data->{image_driver} = '"file:"';
        $data->{image_target} = 'xvda';
    } elsif($hypervisor_type eq 'kvm') {
        $data->{image_driver} = 'raw';
        $data->{image_target} = 'vda';
    }

    my $cluster = $self->_getEntity->getServiceProvider;
    my $template_file = 'image-' . $args{image_name} . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $cluster->getMasterNode,
        file          => $template_file,
        template_dir  => '/templates/components/opennebula',
        template_file => 'image.tt',
        data         => $data,
    );

    $self->getEContext->send(
        src  => $file,
        dest => '/tmp'
    );
    return '/tmp/' . $template_file;
}

# generate vnet template and push it on opennebula master node
# name
sub generateVnetTemplate {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'vnet_name','vnet_bridge', 'vnet_phydev','vnet_netaddress','vnet_mac']
    );

    my $data = {
        vnet_name       => $args{vnet_name},
        vnet_type       => 'FIXED',
        vnet_bridge     => $args{vnet_bridge},
        vnet_vlanid     => $args{vnet_vlanid},
        vnet_phydev     => $args{vnet_phydev},
        vnet_netaddress => $args{vnet_netaddress},
        vnet_mac        => $args{vnet_mac}
    };

    my $cluster = $self->_getEntity->getServiceProvider;
    my $template_file = 'vnet-' . $args{vnet_name} . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $cluster->getMasterNode,
        file          => $template_file,
        template_dir  => '/templates/components/opennebula',
        template_file => 'vnet.tt',
        data         => $data,
    );

    $self->getEContext->send(
        src  => $file,
        dest => '/tmp'
    );
    return '/tmp/' . $template_file;

}

# generate xen vm template and push it on opennebula master node
sub generateXenVmTemplate {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'hypervisor','host']
    );

    # host_ram is stored in octect, so we convert it to megaoctect
    my $ram = General::convertFromBytes(
        value => $args{host}->getAttr(name => 'host_ram'),
        units => 'M'
    );


    my $tftp_conf = $self->{config}->{tftp}->{directory};
    my $cluster = Entity->get(id => $args{host}->getClusterId());

    my $kernel = Entity->get(id => $cluster->getAttr(name => "kernel_id"));
    my $kernel_version = $kernel->getAttr(name => "kernel_version");

    my $disk_params = $cluster->getManagerParameters(manager_type => 'disk_manager');
    my $image = $args{host}->getNodeSystemimage();
    my $image_name = $image->getAttr(name => 'systemimage_name');
    my $hostname = $args{host}->getAttr(name => 'host_hostname');

    my %repo = $self->_getEntity()->getImageRepository(
                   container_access_id => $disk_params->{container_access_id}
               );

    my $repository_path = $self->_getEntity()->getAttr(name => 'image_repository_path') .
                          '/' . $repo{repository_name};

    my $interfaces = [];
    my $bridge = ($args{hypervisor}->getIfaces(role => 'vms'))[0];
    for my $iface ($args{host}->getIfaces()) {
        for my $network ($iface->getInterface->getNetworks) {
            my $vlan = $network->isa("Entity::Network::Vlan") ?
                           $network->getAttr(name => "vlan_number") : undef;

            # generate and register vnet
            my $vnet_template = $self->generateVnetTemplate(
                vnet_name       => $hostname . '-' . $iface->getAttr(name => 'iface_name'),
                vnet_bridge     => "br-" . ($vlan || "default"),
                vnet_phydev     => "p" . $bridge->getAttr(name => "iface_name"),
                vnet_vlanid     => $vlan,
                vnet_mac        => $iface->getAttr(name => 'iface_mac_addr'),
                vnet_netaddress => $iface->getIPAddr
            );
            my $vnetid = $self->onevnet_create(file => $vnet_template);
            push @$interfaces, {
                mac     => $iface->getAttr(name => 'iface_mac_addr'),
                network => $hostname.'-'.$iface->getAttr(name => 'iface_name'),
            };
        };
    }

    my $kernel_filename = 'vmlinuz-' . $kernel_version;
    my $initrd_filename = 'initrd_' . $kernel_version;

    my $data = {
        name            => $hostname,
        memory          => $ram,
        cpu             => $args{host}->host_core,
        kernelpath      => '/var/lib/one/datastores/'.$repo{datastore_id} .'/'. $kernel_filename,
        initrdpath      => '/var/lib/one/datastores/'.$repo{datastore_id} .'/'. $initrd_filename,
        image_name      => $image_name,
        hypervisor_name => $args{hypervisor}->host_hostname,
        interfaces      => $interfaces,
    };

    my $template_file = 'vm-' . $hostname . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $self->_getEntity->getServiceProvider,
        host          => $args{hypervisor},
        file          => $template_file,
        template_dir  => '/templates/components/opennebula',
        template_file => 'xen-vm.tt',
        data         => $data,
    );

    $self->getEContext->send(
        src  => $file,
        dest => '/tmp'
    );


    # If the kernel and the initramfs are not present in the
    # image repository, copy them into it

    my $container_access = Entity->get(id => $disk_params->{container_access_id});
    my $econtainer_access = EFactory::newEEntity(data => $container_access);
    my $mountpoint = $container_access->getContainer->getMountPoint . "_copy_kernel_$kernel_version";

    $econtainer_access->mount(mountpoint => $mountpoint,
                              econtext    => $self->getExecutorEContext);

    if (not -e "$mountpoint/$kernel_filename") {
        $log->info("Copying " . $tftp_conf . "/vmlinuz-" . $kernel_version . " to " . $mountpoint);
        copy($tftp_conf . "/vmlinuz-" . $kernel_version,
             $mountpoint);
    }

    if (not -e "$mountpoint/$initrd_filename") {
        $log->info("Copying " . $tftp_conf . "/initrd_" . $kernel_version . " to " . $mountpoint);
        copy($tftp_conf . "/initrd_" . $kernel_version,
             $mountpoint);
    }

    $econtainer_access->umount(mountpoint => $mountpoint,
                               econtext    => $self->getExecutorEContext);

    return '/tmp/' . $template_file;

}

# generate kvm vm template and push it on opennebula master node
sub generateKvmVmTemplate {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'hypervisor','host']
    );

    # host_ram is stored in octect, so we convert it to megaoctect
    my $ram = General::convertFromBytes(
        value => $args{host}->host_ram,
        units => 'M'
    );

    my $tftp_conf = $self->{config}->{tftp}->{directory};
    my $cluster = Entity->get(id => $args{host}->getClusterId());

    # get the maximum memory from the hosting policy
    my $host_params = $cluster->getManagerParameters(manager_type => 'host_manager');
    my $maxcpu = $host_params->{max_core} || $args{host}->host_core;

    my $maxram = General::convertFromBytes(
        value => General::convertToBytes(
                     value => $host_params->{max_ram} || 0,
                     units => $host_params->{ram_unit}
                 ) || $args{host}->host_ram,
        units => 'M'
    );

    my $disk_params = $cluster->getManagerParameters(manager_type => 'disk_manager');
    my $image = $args{host}->getNodeSystemimage();
    my $image_name = $image->getAttr(name => 'systemimage_name');
    my $hostname = $args{host}->getAttr(name => 'host_hostname');

    my %repo = $self->_getEntity()->getImageRepository(
                   container_access_id => $disk_params->{container_access_id}
               );

    my $repository_path = $self->_getEntity()->getAttr(name => 'image_repository_path') .
                          '/' . $repo{repository_name};

    my $interfaces = [];
    my $bridge = ($args{hypervisor}->getIfaces(role => 'vms'))[0];
    for my $iface ($args{host}->getIfaces()) {
        for my $network ($iface->getInterface->getNetworks) {
            my $vlan = $network->isa("Entity::Network::Vlan") ?
                           $network->getAttr(name => "vlan_number") : undef;


            my $ip;
            eval {
                $ip = $iface->getIPAddr();
            };
            if ($@) {
                my $exception = $@;
                if (Kanopya::Exception::Internal::NotFound->caught()) {
                    next;
                }
                else { $exception->rethrow(); }
            }

            # generate and register vnet
            my $vnet_template = $self->generateVnetTemplate(
                vnet_name       => $hostname.'-'.$iface->getAttr(name => 'iface_name'),
                vnet_bridge     => "br-" . ($vlan || "default"),
                vnet_phydev     => $bridge->getAttr(name => "iface_name"),
                vnet_vlanid     => $vlan,
                vnet_mac        => $iface->getAttr(name => 'iface_mac_addr'),
                vnet_netaddress => $ip
            );

            my $vnetid = $self->onevnet_create(file => $vnet_template);
            push @$interfaces, {
                mac     => $iface->getAttr(name => 'iface_mac_addr'),
                network => $hostname.'-'.$iface->getAttr(name => 'iface_name'),
            };
        };
    }

    my $data = {
        name            => $hostname,
        memory          => $ram,
        maxmem          => $maxram,
        maxcpu          => $maxcpu,
        cpu             => $maxcpu,
        image_name      => $image_name,
        hypervisor_name => $args{hypervisor}->host_hostname,
        interfaces      => $interfaces,
    };

    my $template_file = 'vm-' . $hostname . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $self->_getEntity->getServiceProvider,
        host          => $args{hypervisor},
        file          => $template_file,
        template_dir  => '/templates/components/opennebula',
        template_file => 'kvm-vm.tt',
        data          => $data,
    );

    $self->getEContext->send(
        src  => $file,
        dest => '/tmp'
    );

    return '/tmp/' . $template_file;
}


########################################################
# methods to execute opennebula commands on masternode #
########################################################

sub one_command {
    my ($command) = @_;
    return "su oneadmin -c '" . $command . "'";
}

# declare a datastore from a template file and return the ID
sub onedatastore_create {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['file']
    );

    my $cmd = one_command("onedatastore create $args{file}");
    my $result = $self->getEContext->execute(command => $cmd);
    if($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }

    if($result->{stdout} =~ /(\d+)/) {
        return $1;
    }
}

sub onedatastore_delete {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['datastore_nameorid']
    );

    my $cmd = one_command("onedatastore delete $args{datastore_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onedatastore_list {
    my ($self) = @_;

    my $cmd = one_command("onedatastore list --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    # TODO parse xml output and return hash structure
}

sub onedatastore_show {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['datastore_nameorid']
    );

    my $cmd = one_command("onedatastore show $args{datastore_nameorid} --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    my $xml = XMLin($result->{stdout});
    return $xml;
}

sub oneimage_create {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['datastore_nameorid','file']
    );

    my $cmd = one_command("oneimage create -d $args{datastore_nameorid} $args{file}");
    my $result = $self->getEContext->execute(command => $cmd);
    if($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }
    # TODO parse command output and return image id
}

sub oneimage_delete {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['image_nameorid']
    );

    my $cmd = one_command("oneimage delete $args{image_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub oneimage_list {
    my ($self) = @_;

    my $cmd = one_command("oneimage list --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    # TODO parse xml output and return hash structure
}

sub oneimage_show {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['image_nameorid']
    );

    my $cmd = one_command("oneimage show $args{image_nameorid} --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    my $xml = XMLin($result->{stdout});
    return $xml;
}

sub onevnet_create {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['file']
    );

    my $cmd = one_command("onevnet create $args{file}");
    my $result = $self->getEContext->execute(command => $cmd);
    if($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }
    if($result->{stdout} =~ /(\d+)/) {
        return $1;
    }
}

sub onevnet_delete {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vnet_nameorid']
    );

    my $cmd = one_command("onevnet delete $args{vnet_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevnet_list {
    my ($self) = @_;


    my $cmd = one_command("onevnet list --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    # TODO parse xml output and return hash structure
}

sub onevnet_show {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vnet_nameorid']
    );

    my $cmd = one_command("onevnet show $args{vnet_nameorid} --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    my $xml = XMLin($result->{stdout});
    return $xml;
}

sub onehost_create {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['hostname']
    );

    my $hypervisor_type = $self->getHypervisorType();

    my $cmd = "onehost create $args{hostname} ";
    if($hypervisor_type eq 'xen') {
        $cmd .= '-i im_xen -v vmm_xen -n 802.1Q';
    } elsif($hypervisor_type eq 'kvm') {
        $cmd .= '-i im_kvm -v vmm_kvm -n 802.1Q';
    }

    my $command = one_command($cmd);
    my $result = $self->getEContext->execute(command => $command);
    if($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }
    if($result->{stdout} =~ /(\d+)/) {
        return $1;
    }
}

sub onehost_delete {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['host_nameorid']
    );

    my $cmd = one_command("onehost delete $args{host_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onehost_list {
    my ($self) = @_;

    my $cmd = one_command("onehost list --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    # TODO parse xml output and return hash structure
}

sub onehost_show {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['host_nameorid']
    );

    my $cmd = one_command("onehost show $args{host_nameorid} --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    my $xml = XMLin($result->{stdout});
    return $xml;
}

sub onehost_enable {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['host_nameorid']
    );

    my $cmd = one_command("onehost enable $args{host_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_create {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['file']
    );

    my $cmd = one_command("onevm create $args{file}");
    my $result = $self->getEContext->execute(command => $cmd);
    if($result->{exitcode} != 0) {
        throw Kanopya::Exception::Execution(error => $result->{stdout});
    }
    if($result->{stdout} =~ /(\d+)/) {
        return $1;
    }
}

sub onevm_delete {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid']
    );

    my $cmd = one_command("onevm delete $args{vm_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_deploy {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid', 'host_nameorid']
    );

    my $cmd = one_command("onevm deploy $args{vm_nameorid} $args{host_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_hold {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid']
    );

    my $cmd = one_command("onevm hold $args{vm_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_show {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid']
    );

    my $cmd = one_command("onevm show $args{vm_nameorid} --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    my $xml = XMLin($result->{stdout});
    return $xml;
}

sub onevm_livemigrate {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid','host_nameorid']
    );

    my $cmd = one_command("onevm livemigrate $args{vm_nameorid} $args{host_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_memset {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid','ram']
    );

    my $cmd = one_command("onevm memset $args{vm_nameorid} $args{ram}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_vcpuset {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid','cpu']
    );

    my $cmd = one_command("onevm vcpuset $args{vm_nameorid} $args{cpu}");
    my $result = $self->getEContext->execute(command => $cmd);
}

sub onevm_list {
    my ($self) = @_;

    my $cmd = one_command("onevm list --xml");
    my $result = $self->getEContext->execute(command => $cmd);
    # TODO parse xml output and return hash structure
}

sub onevm_resubmit {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid']
    );

    my $cmd = one_command("onevm resubmit $args{vm_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
}


sub getMaxRamFreeHV{
    my ($self, %args) = @_;
    print "hoho\n";
    my @hypervisors = $self->getHypervisors();

    my $max_hv  = shift @hypervisors;
    my $max_freeram = EFactory::newEEntity(data => $max_hv)->getAvailableMemory->{mem_effectively_available};

    print $max_hv->host_hostname."\n";
    for my $hypervisor (@hypervisors) {
        print $hypervisor->host_hostname."\n";
        my $freeram =  EFactory::newEEntity(data => $hypervisor)->getAvailableMemory->{mem_effectively_available};

        print "hohu\n";
        if ($freeram > $max_freeram) {
            $max_freeram = $freeram;
            $max_hv  = $hypervisor;
        }
    }
    return {
        hypervisor  => $max_hv,
        ram => $max_freeram,
    }
}


1;
