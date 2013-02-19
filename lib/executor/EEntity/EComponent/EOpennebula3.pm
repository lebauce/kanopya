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

=pod

=begin classdoc

TODO

=end classdoc

=cut

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
    if($args{cluster}->getMasterNodeIp() eq $args{host}->adminIp()) {
        my $conf = $self->getConf();
        my $comp = $self->_getEntity();
        my $linux = $args{cluster}->getComponent(category => "System");
        my $oldconf = $linux->getConf();
        my @mountentries;
        my @mounts;

        for my $repo (@{$conf->{opennebula3_repositories}}) {
            if (not defined $repo->{datastore_id}) {
                # declare the datastore
                my $dsid;
                my $ds_name = $repo->{repository_name};
                my $container_access = Entity::ContainerAccess->get(
                                           id => $repo->{container_access_id}
                                       );

                if ($ds_name eq "system") {
                    $dsid = 0;
                } else {
                    my $ds_template = $self->generateDatastoreTemplate(ds_name => $ds_name);
                    $dsid = $self->onedatastore_create(file => $ds_template);

                    # update the datastore id in db
                    $comp->{_dbix}->opennebula3_repositories->search(
                        {repository_name => $ds_name}
                    )->single->update({datastore_id => $dsid});
                }

                # Give rights to the 'oneadmin' user
                my $dir = "/var/lib/one/datastores/$dsid";
                my $command = "mkdir -p $dir; mount -t nfs -o rw,sync,vers=3 " .
                              $container_access->container_access_export . " $dir; " .
                              "chown oneadmin:oneadmin $dir; umount $dir";
                $self->getEContext->execute(command => $command);

                # update linux mount table
                push @mountentries, {
                    linux_mount_dumpfreq   => 0,
                    linux_mount_filesystem => 'nfs',
                    linux_mount_point      => "/var/lib/one/datastores/$dsid",
                    linux_mount_device     => $container_access->container_access_export,
                    linux_mount_options    => 'rw,sync,vers=3',
                    linux_mount_passnum    => 0,
                };
            }
        }

        @mounts = (@{$oldconf->{linuxes_mount}}, @mountentries);
        $linux->setConf(conf => { linuxes_mount => \@mounts });

        for my $vmm ($self->vmms) {
            $linux = $vmm->service_provider->getComponent(category => "System");
            $oldconf = $linux->getConf();
            @mounts = (@{$oldconf->{linuxes_mount}}, @mountentries);
            $linux->setConf(conf => { linuxes_mount => \@mounts });
        }
    }
}

sub registerHypervisor {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );

    my $system = $self->service_provider->getComponent(category => "System");
    my $esystem = EFactory::newEEntity(data => $system);
    $esystem->postStartNode(cluster => $self->service_provider,
                            host    => $args{host});

    my $agent = $self->service_provider->getComponent(category => "Configurationagent");
    my $eagent = EFactory::newEEntity(data => $agent);
    $eagent->postStartNode(cluster => $self->service_provider,
                           host    => $args{host});

    # hypervisor declaration
    my $hostname = $args{host}->node->node_hostname;
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

sub unregisterHypervisor {
    my ($self, %args) = @_;

    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );

    $self->onehost_delete(host_nameorid => $args{host}->onehost_id);

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

    # $log->debug("Apply VLAN on the destination hypervisor");
    # $self->propagateVLAN(host       => $args{host},
    #                      hypervisor => $args{hypervisor_dst});

    $self->onevm_livemigrate(
        vm_nameorid   => $args{host}->node->node_hostname,
        host_nameorid => $args{hypervisor_dst}->node->node_hostname,
    );

    return $src_hypervisor;
}

sub getVMState {
    my ($self,%args) = @_;

    General::checkParams(args     => \%args, required => ['host']);

    my $hxml = $self->onevm_show(vm_nameorid => $args{host}->node->node_hostname);

    my $history = $hxml->{HISTORY_RECORDS}->{HISTORY};
    my $hypervisor_migr;

    if (ref $history eq 'HASH') {
        $hypervisor_migr = $history->{HOSTNAME};
    }
    elsif (ref $history eq 'ARRAY')  {
        $hypervisor_migr =  $history->[-1]->{HOSTNAME};
    }

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

sub scaleMemory {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'memory' ]);

    $self->onevm_memset(vm_nameorid => $args{host}->node->node_hostname, ram => $args{memory} / 1024 / 1024);
}

sub restoreHost {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => [ 'hypervisor' ],
                         optional => { check_resubmit   => undef,
                                       check_hypervisor => undef,
                                       check_resources  => undef });

    my $host_name = $args{hypervisor}->node->node_hostname;
    my $vms       = $args{hypervisor}->getVms();

    if (defined $args{check_resubmit} || defined $args{check_hypervisor}) {
        for my $vm (@{$vms}) {
            my $state = $self->getVMState(host => $vm );

            $log->info('vm <'.($vm->getId).'> hv '.$state->{hypervisor}.' state '.$state->{state});
            if($state->{state} eq 'runn') {
                if (defined $args{hypervisor}) {
                    if(!($args{hypervisor}->node->node_hostname eq $state->{hypervisor})){
                        $log->info('VM running on a wrong hypervisor');
                        $vm->setAttr(
                            name  => 'hypervisor_id',
                            value => Entity::Host->find(hash => {
                                         'node.node_hostname' => $state->{hypervisor}
                                     })->id
                        );
                        $vm->save();
                    }
                }
            }
            else {
                if (defined $args{check_resubmit}){
                    $self->onevm_resubmit(vm_nameorid => $vm->node->node_hostname);
                }
            }
        }
    }

    if (defined $args{check_resources}) {
        my $host_vm_capacities = $args{hypervisor}->getVmResources();

        $log->info(Dumper $host_vm_capacities);

        for my $vm (@{$vms}) {
            $log->info('VM <'.($vm->getId()).'> <'.($vm->node->node_hostname).'>');

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
sub scaleCpu {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'cpu_number' ]);

    my $cpu_number = $args{cpu_number};

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
    $self->onevm_vcpuset(vm_nameorid => $args{host}->node->node_hostname, cpu => $cpu_number);
}

sub retrieveOpennebulaHypervisorStatus {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'host' ]
    );

    my $hxml = $self->onehost_show(host_nameorid => $args{host}->node->node_hostname);
    if($hxml->{STATE} != 2) {
        $log->info('hypervisor <'.$args{host}->node->node_hostname.'> error for opennebula');
        return 0;
    }

    $log->info('hypervisor <'.$args{host}->node->node_hostname.'> running for opennebula');
    return 1;
}

sub halt {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'host' ]);
    # retrieve vm info from opennebula
    $self->onevm_shutdown(vm_nameorid => $args{host}->node->node_hostname);
}


sub isUp {
    my ($self, %args) = @_;
    General::checkParams(
        args     => \%args,
        required => [ 'cluster', 'host' ]
    );

    my $hostip = $args{host}->adminIp;
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
    my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
    my $image = $args{host}->getNodeSystemimage();
    my $image_name = $image->systemimage_name;

    my %repo = $self->_getEntity()->getImageRepository(
                   container_access_id => $disk_params->{container_access_id}
               );

    my $image_templatefile = $self->generateImageTemplate(
        image_name        => $image_name,
        image_source      => $repo{datastore_id} . '/' . $image->getContainer->container_device,
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

    # create the vm from template
    my $vmid = $self->onevm_create(file => $vm_templatefile);

    # declare vm in database
    $log->info('vm id returned by opennebula: '.$vmid);

    # deploy the VM as the OpenNebula's scheduler sometimes refuse to deploy it
    my $cmd = one_command("onevm deploy " . $args{host}->node->node_hostname .
                          " " . $hypervisor->node->node_hostname);

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

    my $hostname = $args{host}->node->node_hostname;

    my $image = $args{host}->getNodeSystemimage();

    my $xml = $self->onevm_show(vm_nameorid => $hostname);

    # delete the vm
    $self->onevm_delete(vm_nameorid => $hostname);

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

    my $hxml    = $self->onevm_show(vm_nameorid => $args{host}->node->node_hostname);

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

    my $command = one_command('tail -n 10 /var/log/one/'.($args{opennebula3_vm}->onevm_id).'.log');

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
        vm_nameorid   => $args{vm}->node->node_hostname,
        host_nameorid => $args{hypervisor}->node->node_hostname,
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

    my $cluster = $self->service_provider;
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

    my $cluster = $self->service_provider;
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

    my $cluster = $self->service_provider;
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

    my $cluster = $self->service_provider;
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
        value => $args{host}->host_ram,
        units => 'M'
    );

    my $tftp_conf = $self->{config}->{tftp}->{directory};
    my $cluster = Entity->get(id => $args{host}->getClusterId());

    my $kernel = Entity->get(id => $cluster->getAttr(name => "kernel_id"));
    my $kernel_version = $kernel->kernel_version;

    my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
    my $image = $args{host}->getNodeSystemimage();
    my $image_name = $image->systemimage_name;
    my $hostname = $args{host}->node->node_hostname;

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
        hypervisor_name => $args{hypervisor}->node->node_hostname,
        interfaces      => $interfaces,
    };

    my $template_file = 'vm-' . $hostname . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $self->service_provider,
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
    my $mountpoint = $container_access->getMountPoint . "_copy_kernel_$kernel_version";

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

    General::checkParams(args     => \%args,
                         required => [ 'hypervisor','host']);

    # host_ram is stored in octect, so we convert it to megaoctect
    my $ram = General::convertFromBytes(
                  value => $args{host}->host_ram,
                  units => 'M'
              );

    my $tftp_conf = $self->{config}->{tftp}->{directory};
    my $cluster = Entity->get(id => $args{host}->getClusterId());

    # get the maximum memory from the hosting policy
    my $host_params = $cluster->getManagerParameters(manager_type => 'HostManager');
    my $maxcpu = $host_params->{max_core} || $args{host}->host_core;
    my $maxram = General::convertFromBytes(
                     value => $host_params->{max_ram}  || $args{host}->host_ram,
                     units => 'M'
                 );

    my $disk_params = $cluster->getManagerParameters(manager_type => 'DiskManager');
    my $image = $args{host}->getNodeSystemimage();
    my $image_name = $image->systemimage_name;
    my $hostname = $args{host}->node->node_hostname;

    my %repo = $self->getImageRepository(
                   container_access_id => $disk_params->{container_access_id}
               );

    my $repository_path = $self->image_repository_path . '/' . $repo{repository_name};

    my $interfaces = [];
    my @bridges = $args{hypervisor}->getIfaces(role => 'vms');
    for my $iface ($args{host}->getIfaces()) {
        # Look for an appropriate bridge
        my @vm_networks;

        for my $vm_netconf ($iface->netconfs) {
            for my $vm_poolip ($vm_netconf->poolips) {
                push @vm_networks, $vm_poolip->network;
            }
        }

        my $found_bridge = undef;
        BRIDGE:
        for my $bridge (@bridges) {
            my @unsatisfied_networks = @vm_networks;
            for my $netconf ($bridge->netconfs) {
                for my $poolip ($netconf->poolips) {
                    @unsatisfied_networks = grep { $_->id != $poolip->network->id } @vm_networks;
                }
            }

            if ((scalar @unsatisfied_networks) == 0) {
                $found_bridge = $bridge;
                last BRIDGE;
            }
        }

        if (not defined ($found_bridge)) {
            throw Kanopya::Exception::Execution(error => "Could not find a bridge that match the requirements");
        }

        my $vlan = undef;
        my @netconfs = $iface->netconfs;
        if (scalar @netconfs) {
            my $netconf = pop @netconfs;
            my @vlans = $netconf->vlans;
            if (scalar @vlans) {
                $vlan = pop @vlans;
                my $ehost_manager = EFactory::newEEntity(data => $args{hypervisor}->getHostManager);
                $ehost_manager->applyVLAN(iface  => $found_bridge,
                                          vlan   => $vlan);
            }
        }

        # generate and register vnet
        my $vnet_template = $self->generateVnetTemplate(
            vnet_name       => $hostname . '-' . $iface->iface_name,
            vnet_bridge     => "br-" . ($vlan || "default"),
            vnet_phydev     => "p" . $found_bridge->iface_name,
            vnet_vlanid     => defined $vlan ? $vlan->vlan_number : undef,
            vnet_mac        => $iface->iface_mac_addr,
            vnet_netaddress => $iface->getIPAddr
        );

        my $vnetid = $self->onevnet_create(file => $vnet_template);
        push @$interfaces, {
            mac     => $iface->iface_mac_addr,
            network => $hostname . '-' . $iface->iface_name,
        };
    }

    my $data = {
        name            => $hostname,
        memory          => $ram,
        maxmem          => $maxram,
        maxcpu          => $maxcpu,
        cpu             => $maxcpu,
        image_name      => $image_name,
        hypervisor_name => $args{hypervisor}->node->node_hostname,
        interfaces      => $interfaces,
    };

    my $template_file = 'vm-' . $hostname . '.tt';
    my $file = $self->generateNodeFile(
        cluster       => $self->service_provider,
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

sub onevm_shutdown {
    my ($self,%args) = @_;
    General::checkParams(
        args     => \%args,
        required => ['vm_nameorid']
    );

    my $cmd = one_command("onevm shutdown $args{vm_nameorid}");
    my $result = $self->getEContext->execute(command => $cmd);
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
    my @hypervisors = $self->hypervisors();

    my $max_hv  = shift @hypervisors;
    my $max_freeram = EFactory::newEEntity(data => $max_hv)->getAvailableMemory->{mem_effectively_available};

    for my $hypervisor (@hypervisors) {
        my $freeram = EFactory::newEEntity(data => $hypervisor)->getAvailableMemory->{mem_effectively_available};

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

=cut

=begin classdoc

Check the state of the vm

@return boolean

=end classdoc

=cut

sub checkUp {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "host" ]);

    my $host = $args{host};
    my $vm_state = $self->getVMState(host => $host);

    $log->info('VM <' . $host->id . '> opennebula status <' . ($vm_state->{state}) . '>');

    if ($vm_state->{state} eq 'runn') {
        $log->info('VM running try to contact it');
        return 1;
    }
    elsif ($vm_state->{state} eq 'boot') {
        $log->info('VM still booting');
        return 0;
    }
    elsif ($vm_state->{state} eq 'fail' ) {
        my $lastmessage = $self->vmLoggedErrorMessage(opennebula3_vm => $host);
        throw Kanopya::Exception(error => 'VM fail on boot: ' . $lastmessage);
    }
    elsif ($vm_state->{state} eq 'pend' ) {
        $log->info('VM still pending'); #TODO check HV state
        return 0;
    }

    return 0;
}

1;
