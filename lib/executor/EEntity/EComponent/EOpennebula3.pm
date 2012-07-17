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
use base "EManager::EHostManager";

use strict;
use warnings;
use Entity;
use EFactory;
use General;
use CapacityManagement;
use XML::Simple;
use Log::Log4perl "get_logger";
use Data::Dumper;
use NetAddr::IP;
use File::Copy;

my $log = get_logger("executor");
my $errmsg;

# generate configuration files on node
sub configureNode {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['cluster', 'host', 'mount_point']);

    my $masternodeip = $args{cluster}->getMasterNodeIp();

    if(not $masternodeip) {
        # we start the first node so we start opennebula services
        $log->info('opennebula frontend configuration');
        $log->debug('generate /etc/one/oned.conf');

        $self->generateOnedConf(%args);

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

        my $exports = "/var/lib/one $network(rw,no_root_squash,no_subtree_check)\n";
        my $cmd = "echo '$exports' > " .$args{mount_point}."/etc/exports";
        $self->getExecutorEContext->execute(command => $cmd);

    } else {
        my $mount = $masternodeip.":/var/lib/one /var/lib/one nfs rw,sync,vers=3 0 0\n";
        my $cmd = "echo '$mount' >> ".$args{mount_point}."/etc/fstab";
        $self->getExecutorEContext->execute(command => $cmd);
    }

    $log->info("Opennebula cluster's node configuration");
    $log->debug('generate /etc/default/libvirt-bin');
    $self->generateLibvirtbin(%args);

    $log->debug('generate /etc/libvirt/libvirtd.conf');
    $self->generateLibvirtdconf(%args);

    $log->debug('generate /etc/libvirt/qemu.conf');
    $self->generateQemuconf(%args);

    $self->generateXenconf(%args);

    $self->addInitScripts(
          mountpoint => $args{mount_point},
          scriptname => 'xend',
    );

   $self->addInitScripts(
          mountpoint => $args{mount_point},
          scriptname => 'xendomains',
   );

    $self->addInitScripts(
          mountpoint => $args{mount_point},
          scriptname => 'libvirt-bin',
   );

   $self->addInitScripts(
          mountpoint => $args{mount_point},
          scriptname => 'qemu-kvm',
   );
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
    my $src_hypervisor = $self->getHypervisorHost(
                             host => $args{host}
                         );
    $log->debug("The VM <" . $args{host}->getId . "> is on the <" . $src_hypervisor->getId . "> host");

    my $hypervisor_id = $self->_getEntity()->getHypervisorIdFromHostId(host_id => $args{hypervisor_dst}->getAttr(name => "host_id"));
    my $hypervisor_host_name = $args{hypervisor_dst}->getAttr(name=>'host_hostname');

    my $host_id = $self->_getEntity()->getVmIdFromHostId(host_id => $args{host}->getAttr(name => "host_id"));

    $log->debug("Apply VLAN on the destination hypervisor");
    $self->propagateVLAN(host       => $args{host},
                         hypervisor => $args{hypervisor_dst});

    my $command_to_exec = "onevm livemigrate $host_id $hypervisor_id" ;
    my $command = $self->_oneadmin_command(command => $command_to_exec);
    my $result = $masternode_econtext->execute(command => $command);
    $log->debug('Migration command: '.$command_to_exec);

    return $src_hypervisor;
}


sub checkMigration {
    my ($self,%args) = @_;

    General::checkParams(args     => \%args,
                         required => [
                            'host',
                            'hypervisor_src',
                            'hypervisor_cluster'
    ]);

    my $masternodeip = $args{hypervisor_cluster}->getMasterNodeIp();
    my $masternode_econtext = EFactory::newEContext(ip_source      => $self->getExecutorEContext->getLocalIp,
                                                    ip_destination => $masternodeip);

    my $host_id = $self->_getEntity()->getVmIdFromHostId(host_id => $args{host}->getAttr(name => "host_id"));

    my $command = $self->_oneadmin_command(command => "onevm show $host_id --xml");
    my $result = $masternode_econtext->execute(command => $command);
    my $hxml = XMLin($result->{stdout});

    my $history = $hxml->{HISTORY_RECORDS}->{HISTORY};
    my $hypervisor_migr;

    if (ref $history eq 'HASH') {
        $hypervisor_migr = $history->{HOSTNAME};
    }
    else {
        $hypervisor_migr =  $history->[-1]->{HOSTNAME};
    }

    my $state = $hxml->{LCM_STATE};

    return { state => $state, hypervisor => $hypervisor_migr };

        # $self->propagateVLAN(host       => $args{host},
        #                      hypervisor => $args{hypervisor_src},
        #                      delete     => 1);
}

# execute memory scale in
sub scale_memory {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'memory' ]);

    my $memory = $args{memory};

    my $host_id = $self->_getEntity()->getVmIdFromHostId(
                      host_id => $args{host}->getAttr(name => "host_id")
                  );
    my $command = $self->_oneadmin_command(command => "onevm memset $host_id $memory");

    $self->getEContext->execute(command => $command);

    # Memroy scale checked in post requisite before saving in DB
    # return $self->_getEntity()->updateMemory(%args);
}



sub restoreHost {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['hypervisor_host_id']);
    # Option  memory, hypervisor, resubmit
    my $host_name = Entity::Host->get(id => $args{hypervisor_host_id})->host_hostname;
    my $vms = $self->_getEntity
                   ->getVmsFromHypervisorHostId(
                        hypervisor_host_id => $args{hypervisor_host_id}
                     );


    for my $vm (@{$vms}) {

        # Get vm id in opennebula
        my $host_id = $self->getVmIdFromHostId(host_id => $vm->getAttr(name => "host_id"));
        my $command = $self->_oneadmin_command(command => "onevm show $host_id --xml");
        my $result  = $self->getEContext->execute(command => $command);
        my $hxml = XMLin($result->{stdout});
        my $history = $hxml->{HISTORY_RECORDS}->{HISTORY};
        my $hypervisor;

        if (ref $history eq 'HASH') {
            $hypervisor = $history->{HOSTNAME};
        }
        else {
            $hypervisor =  $history->[-1]->{HOSTNAME};
        }

        my $state  = $hxml->{LCM_STATE};
        my $memory = $hxml->{MEMORY} * 1024;

        $log->info('vm '.$hxml->{ID}.' hv '.$hypervisor.' state '.$state);
        if($state == 3) {
            if (defined $args{hypervisor}) {
                if(!($hypervisor eq $host_name)){
                   $log->info("VM running on a wrong hypervisor");
                }
            }
           if (defined $args{memory}){
                if( $memory != $vm->getHostRAM()){
                    $log->info("Memory one = $memory VS db = ".($vm->getHostRAM()));
                    $vm->setAttr(name => 'host_ram', value => $memory);
                    $vm->save();
                }
           }
        }
        else{
            if(defined $args{resubmit}){
                $log->info("onevm resubmit $hxml->{ID}");
                my $command = $self->_oneadmin_command(command => "onevm resubmit $hxml->{ID}");
                my $result  = $self->getEContext->execute(command => $command);
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

    my $host_id = $self->_getEntity()->getVmIdFromHostId(
                      host_id => $args{host}->getAttr(name => "host_id")
                  );
    my $command = $self->_oneadmin_command(command => "onevm vcpuset $host_id $cpu_number");

    $self->getEContext->execute(command => $command);

    return $self->_getEntity()->updateCPU(%args);
}

# generate $ONE_LOCATION/etc/oned.conf configuration file
sub generateOnedConf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point']);

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

# generate /etc/default/libvirt-bin configuration file
sub generateLibvirtbin {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    my $cluster = $self->_getEntity->getServiceProvider;
    my $data = $self->_getEntity()->getTemplateDataLibvirtbin();
    my $file = $self->generateNodeFile(
        cluster       => $cluster,
        host          => $args{host},
        file          => '/etc/default/libvirt-bin',
        template_dir  => "/templates/components/opennebula",
        template_file => 'libvirt-bin.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/default'
    );
}

# generate /etc/libvirt/libvirtd.conf configuration file
sub generateLibvirtdconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    my $data = $self->_getEntity()->getTemplateDataLibvirtd();
    $data->{listen_ip_address} = $args{host}->getAdminIp;
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/libvirt/libvirtd.conf',
        template_dir  => '/templates/components/opennebula',
        template_file => 'libvirtd.conf.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/libvirt'
    );
}

# generate /etc/libvirt/qemu.conf configuration file
sub generateQemuconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    my $data = {};
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/libvirt/qemu.conf',
        template_dir  => '/templates/components/opennebula',
        template_file => 'qemu.conf.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/libvirt'
    );
}

# generate /etc/xen/xend-config.sxp configuration file
sub generateXenconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    # TODO recup de l'interface pour les vms
    my $data = {
             vmiface => 'eth1',
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

sub generatemultivlanconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    my $data = {};
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/xen/scripts/network-multi-vlan',
        template_dir  => '/templates/components/opennebula',
        template_file => 'network-multi-vlan.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/xen/scripts'
    );
}

sub generatevlanconf {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);

    my $data = {};
    my $file = $self->generateNodeFile(
        cluster       => $args{cluster},
        host          => $args{host},
        file          => '/etc/xen/scripts/network-bridge-vlan',
        template_dir  => '/templates/components/opennebula',
        template_file => 'network-bridge-vlan.tt',
        data          => $data
    );

    $self->getExecutorEContext->send(
        src  => $file,
        dest => $args{mount_point}.'/etc/xen/scripts'
    );
}

sub addNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'mount_point', 'cluster' ]);
    $self->configureNode(%args);
}

sub postStartNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ]);

    # this host is a new hypervisor node so we declare it to opennebula
    my $hostname = $args{host}->getAttr(name => 'host_hostname');
    my $command = $self->_oneadmin_command(command => "onehost create $hostname im_xen vmm_xen tm_shared 802.1Q");

    sleep(10);
    my $result = $self->getEContext->execute(command => $command);
    my $id = substr($result->{stdout}, 4);

    $log->info('hypervisor id returned by opennebula: '.$id);
    $self->_getEntity()->addHypervisor(
        host_id => $args{host}->getAttr(name => 'host_id'),
        id      => $id,
    );
    $command = $self->_oneadmin_command(command => "onehost enable $hostname");
    $result = $self->getEContext->execute(command => $command);
}

sub preStopNode {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['cluster', 'host' ]);

    my $id = $self->_getEntity()->getHypervisorIdFromHostId(host_id => $args{host}->getAttr(name => 'host_id'));
    my $command = $self->_oneadmin_command(command => "onehost delete $id");

     sleep(10);
     my $result = $self->getEContext->execute(command => $command);
     # TODO verifier le succes de la commande
     $self->_getEntity()->removeHypervisor(host_id => $args{host}->getAttr(name => 'host_id'));
}

sub isUp {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'cluster', 'host' ] );
    my $ip = $args{host}->getAdminIp;

    if($args{cluster}->getMasterNodeIp() eq $ip) {
        # host is the opennebula frontend
        # we must test opennebula port reachability
        my $net_conf = $self->{_entity}->getNetConf();
        my ($port, $protocols) = each %$net_conf;
        my $cmd = "nmap -n -sT -p $port $ip | grep $port | cut -d\" \" -f2";
        my $port_state = `$cmd`;
        chomp($port_state);
        $log->debug("Check host <$ip> on port $port ($protocols->[0]) is <$port_state>");
        if ($port_state eq "closed"){
            return 0;
        }
    } else {
        # host is an hypervisor node
        # we must test libvirtd port reachability
        my $port = 16509;
        my $proto = 'tcp';
        my $cmd = "nmap -n -sT -p $port $ip | grep $port | cut -d\" \" -f2";
        my $port_state = `$cmd`;
        chomp($port_state);
        $log->debug("Check host <$ip> on port $port ($proto) is <$port_state>");
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

    my $cm = CapacityManagement->new(cluster_id => $args{host}->getClusterId());

    my $hypervisor_id = $cm->getHypervisorIdForVM(
        wanted_values => {
            ram => $args{host}->getAttr(name => 'host_ram'),
            cpu => $args{host}->getAttr(name => 'host_core'),
        }
    );

    if( !defined $hypervisor_id){
        my $errmsg = "Cannot add node in cluster ".$args{host}->getClusterId().", not enough resources\n";
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    # Pick up an hypervisor

    my $hypervisor = Entity::Host->get(id => $hypervisor_id);
    $log->info("Picked up hypervisor " . $hypervisor->getId());

    # generate template in opennebula master node
    my $vm_template = $self->_generateVmTemplate(
                          host       => $args{host},
                          hypervisor => $hypervisor,
                      );

    # Apply the VLAN's on the hypervisor interface dedicated to virtual machines
    $self->propagateVLAN(host       => $args{host},
                         hypervisor => $hypervisor);

    # create the vm from template
    my $command = $self->_oneadmin_command(command => "onevm create $vm_template");
    my $result = $self->getEContext->execute(command => $command);

    # declare vm in database
    my $id = substr($result->{stdout}, 4);
    $log->info('vm id returned by opennebula: '.$id);

    # $command = $self->_oneadmin_command(command => "onevm hold $id");
    # $result = $masternode_econtext->execute(command => $command);

    $self->_getEntity()->addVM(
        host       => $args{host},
        id         => $id,
        hypervisor => $hypervisor
    );

}

# delete a vm from opennebula
sub stopHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host' ]);

    # retrieve vm info from opennebula

    my $id = $self->_getEntity()->getVmIdFromHostId(host_id => $args{host}->getAttr(name => 'host_id'));
    my $command = $self->_oneadmin_command(command => "onevm delete $id");
    my $result = $self->getEContext->execute(command => $command);

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

    my $id = $self->_getEntity()->getVmIdFromHostId(host_id => $args{host}->getAttr(name => 'host_id'));
    my $command = $self->_oneadmin_command(command => "onevm show $id --xml");
    my $result = $self->getEContext->execute(command => $command);
    my $hxml = XMLin($result->{stdout});

    my $vnc_port = $hxml->{TEMPLATE}->{GRAPHICS}->{PORT};

    $self->_getEntity()->updateVM(
        vm_host_id    => $args{host}->getAttr(name => 'host_id'),
        vnc_port      => $vnc_port,
    );
}

sub getFreeHost {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "ram", "core", "ifaces" ]);

    if ($args{ram_unit}) {
        $args{ram} = General::convertToBytes(value => $args{ram}, units => $args{ram_unit});
        delete $args{ram_unit};
    }

    $log->info("Looking for a virtual host");
    my $host = eval{
        return $self->_getEntity->createVirtualHost(
                   core   => $args{core},
                   ram    => $args{ram},
                   ifaces => $args{ifaces},
               );
    };
    if ($@) {
        my $error =$@;
        # We can't create virtual host for some reasons (e.g can't meet constraints)
        $log->debug("Component OpenNebula3 <" . $self->_getEntity->getAttr(name => 'component_id') .
                    "> No capabilities to host this vm core <$args{cpu}> and ram <$args{ram}>:\n" . $error);
    }

    return $host;
}

# generate vm template and push it on opennebula master node
sub _generateVmTemplate {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'hypervisor','host']);

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
    my $image_name = $image->getAttr(name => 'systemimage_name') . '.img';
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

            my $data = {
                mac => $iface->getAttr(name => 'iface_mac_addr'),
                bridge  => "br-" . ($vlan || "default"),
                phydev  => "p" . $bridge->getAttr(name => "iface_name"),
                vlan    => $vlan
            };
            push @{$interfaces}, $data;
        };
    }

    my $kernel_filename = 'vmlinuz-' . $kernel_version;
    my $initrd_filename = 'initrd_' . $kernel_version;

    my $data = {
        name            => $hostname,
        memory          => $ram,
        cpu             => $args{host}->host_core,
        kernelpath      => $repository_path . '/' . $kernel_filename,
        initrdpath      => $repository_path . '/' . $initrd_filename,
        imagepath       => $repository_path . '/' . $image_name,
        bridge_iface    => ($args{hypervisor}->getIfaces(role => "vms"))[0]->iface_name,
        hypervisor_type => $self->_getEntity->hypervisor,
        hypervisor_name => $args{hypervisor}->host_hostname,
        interfaces      => $interfaces,
    };

    my $file = $self->generateNodeFile(
        cluster       => $self->_getEntity->getServiceProvider,
        host          => $args{hypervisor},
        file          => '/tmp/vm.template',
        template_dir  => '/templates/components/opennebula',
        template_file => 'vm.tt',
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

    return '/tmp/vm.template';
}

# prefix commands to use oneadmin account with its environment variables
sub _oneadmin_command {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['command']);

    my $config = $self->_getEntity()->getConf();
    return "su oneadmin -c '" . $args{command} . "'";
}

sub applyVLAN {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'iface', 'vlan' ]);

    # In the case of OpenNebula, we need to apply the VLAN on the
    # bridge interface of the hypervisor the VM is running on.
}

# Apply the VLAN's on the hypervisor interface dedicated to virtual machines

sub propagateVLAN {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'host', 'hypervisor' ]);

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

1;
