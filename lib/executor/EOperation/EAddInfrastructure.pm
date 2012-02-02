# EAddCluster.pm - Operation class implementing Cluster creation operation

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EEntity::Operation::EAddInfrastructure - Operation class implementing Infrastructure creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Infrastructure creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EAddInfrastructure;
use base "EOperation";

use strict;
use warnings;

use JSON -support_by_pp;
use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::Infrastructure;
use Entity::Systemimage;
use Entity::Distribution;
use Entity::Tier;
use Entity::ServiceProvider::Inside::Cluster;
use EEntity::EComponent::ELvm2;
use EEntity::EComponent::EIscsitarget1;
use EEntity::EComponent::ENfsd3;
use EEntity::EComponent::EMounttable1;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 new

    my $op = EEntity::EOperation::EAddHost->new();

EEntity::Operation::EAddHost->new creates a new AddMotheboard operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init() is a private method used to define internal parameters.

=cut

sub _init {
    my $self = shift;
    $self->{nas} = {};
    return;
}

=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();

    
    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    my $adm = Administrator->new();
    my $params = $self->_getOperation()->getParams();
    # ARG BAD, Trying to get internal_network
    $self->{internal_network} = $args{internal_cluster};
    $self->{_file_path} = $params->{file_path};
    
    $self->{_file_path} =~ /.*\/(.*)$/;
    my $file_name = $1;
    $self->{_file_name} = $file_name;

    $self->{_objs} = {};
    
    # Load Nas Cluster
    $self->{nas}->{obj} = Entity::ServiceProvider::Inside::Cluster->get(id => $args{internal_cluster}->{nas});
    $self->loadContext(internal_cluster => $args{internal_cluster}, service => "nas");

    # Instanciate Storage component.
    my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
                                                version => "2");
    $self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
    $log->debug("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));

    # Instanciate Iscsi Export component.
    $self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
                                                                                                        version=> "1"));
    $log->debug("Load iscsi export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));

    # Instanciate nfsd Export component.
    $self->{_objs}->{component_nfs_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Nfsd",
                                                                                                        version=> "3"));
    $log->debug("Load nfs export component (nfsd version 3, it ref is " . ref($self->{_objs}->{component_nfs_export}));

    # Load Local econtext
    $self->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");

}



sub execute {
    my $self = shift;

    my $adm = Administrator->new();

    my $infrastructure_def;
    my $json_infra= new JSON;
    my $json;
    {
        local $/; #enable slurp
        open my $fh, "<", $self->{_file_path};
        $json = <$fh>;
        close $fh;
    }
    #Import json
    $json_infra->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey();
    $infrastructure_def = $json_infra->decode($json);

    my $local_nameserver = "127.0.0.1";
    #TODO dev kanopya->getLocalNameserver

    # Prepare infrastructure definition
    my $infrastructure = {
        infrastructure_reference    => $infrastructure_def->{reference},
        infrastructure_min_node     => $infrastructure_def->{size}->{min},
        infrastructure_max_node     => $infrastructure_def->{size}->{max},
        infrastructure_version      => $infrastructure_def->{version},
        infrastructure_desc         => $infrastructure_def->{description},
        infrastructure_domainname   => $infrastructure_def->{domain_name},
        infrastructure_nameserver   => $local_nameserver,
        infrastructure_tier_number  => $infrastructure_def->{tier_number},
        infrastructure_name         => $infrastructure_def->{name},
        infrastructure_priority     => $infrastructure_def->{priority},
    };
    # Infrastructure instantiation
    eval {
        $self->{_objs}->{infrastructure} = Entity::Infrastructure->new(%$infrastructure);
    };
    if($@) {
        my $err = $@;
        $errmsg = "EOperation::EAddInfrastructure->prepare : Infrastructure instanciation failed because : " . $err;
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    $self->{_objs}->{infrastructure}->save();
    my $tiers = $infrastructure_def->{tier};
    my $i =0;
    $self->{_objs}->{tiers} = [];
    $self->{_objs}->{clusters} = [];
    $self->{_objs}->{systemimage} = [];
    my $public_ip_id = $adm->{manager}->{network}->newPublicIP('ip_address'   => $infrastructure_def->{public_ip}->{addr},
                                                               'ip_mask'      => $infrastructure_def->{public_ip}->{netmask});

    foreach my $tier (@$tiers) {

        my $tier_fullname = $infrastructure_def->{reference} . "_" .$infrastructure_def->{name} . "_" . $tier->{name};
        
        # Prepare disk to add data
        my $disk_name = $infrastructure_def->{reference} . "_" .$infrastructure_def->{name} . "_" .$tier->{name} ."_data";
        my $tier_data_disk_id = $self->{_objs}->{component_storage}->createDisk(name       => $disk_name,
                                                                                size       => $tier->{data}->[0]->{size},
                                                                                filesystem => "ext3",
                                                                                econtext   => $self->{nas}->{econtext},
                                                                                erollback  => $self->{erollback});
        my $vg_name = $self->{_objs}->{component_storage}->_getEntity()->getMainVg()->{vgname};
        # Add data from repository to data disk
        # Mount data disk to populate it
        my $mkdir_cmd = "mkdir -p /mnt/$tier_fullname";
        $self->{nas}->{econtext}->execute(command => $mkdir_cmd);
        my $mount_cmd = "mount /dev/". $vg_name ."/" . $disk_name . " /mnt/$tier_fullname";
        $self->{nas}->{econtext}->execute(command => $mount_cmd);

        my $cp_cmd = "$tier->{data}->[0]->{transfert_mode} $tier->{data}->[0]->{repository}* /mnt/$tier_fullname/";
        $self->{nas}->{econtext}->execute(command => $cp_cmd);
        # Umount data disk
        my $sync_cmd = "sync";
        $self->{nas}->{econtext}->execute(command => $sync_cmd);
        my $umount_cmd = "umount /mnt/$tier_fullname";
        $self->{nas}->{econtext}->execute(command => $umount_cmd);
        my $rmdir_cmd = "rmdir /mnt/$tier_fullname";
        $self->{nas}->{econtext}->execute(command => $rmdir_cmd);

        # Export data disk
        if ($tier->{data}->[0]->{exporter} eq "iscsi"){
        $self->{_objs}->{component_export}->createExport(export_name   => $disk_name,
                                                          device_name   => "/dev/". $vg_name ."/" . $disk_name,
                                                          typeio        => "Fileio",
                                                          iomode        => "ro",
                                                          econtext      => $self->{nas}->{econtext},
                                                          erollback     => $self->{erollback});
        }
        elsif ($tier->{data}->[0]->{exporter} eq "nfs"){
            my $export_id = $self->{_objs}->{component_nfs_export}->addExport(
                                                                    device      => "/dev/". $vg_name ."/" . $disk_name,
                                                                    econtext    =>  $self->{nas}->{econtext});
         $self->{_objs}->{component_nfs_export}->addExportClient(
                                                                export_id => $export_id,
                                                                client_name => $adm->{manager}->{network}->getInternalNetwork(),
                                                                client_options => "rw,sync,no_subtree_check");
        
        $self->{_objs}->{component_nfs_export}->update_exports(econtext => $self->{nas}->{econtext});
        $log->info("Add NFS Export of device </dev/". $vg_name ."/" . $disk_name .">");
        }
        else {
            $errmsg = "Wrong exporter used $tier->{data}->[0]->{exporter}";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }

        my ($min_node, $max_node, $cluster_si_access_mode, $si_dedicated);
        # nowaday, we only managed LAMP business apps.
        if ($tier->{rank} == 1) {
            $min_node = 1;
            $max_node = $infrastructure_def->{size}->{max} - 1;
            $cluster_si_access_mode = "ro";
            $si_dedicated = 0;
            
        } else {
            $min_node = 1;
            $max_node = 1;
            $cluster_si_access_mode = "rw";
            $si_dedicated = 1;
        }
        
        # Create System Image from distribution_id
        $self->{_objs}->{systemimage}->[$i] = Entity::Systemimage->new(systemimage_name         => "si_$tier_fullname",
                                                                       systemimage_desc         => "This is the system image is used by the tier <".$tier->{name}."> of infrastructure <" . $infrastructure_def->{name} .">",
                                                                       systemimage_dedicated    => $si_dedicated,
                                                                       distribution_id          => $tier->{distribution_id});
        $self->{_objs}->{distribution} = Entity::Distribution->get(id => $tier->{distribution_id});
        delete $tier->{distribution_id};
        my $devs = $self->{_objs}->{distribution}->getDevices();
        my $esystemimage = EFactory::newEEntity(data => $self->{_objs}->{systemimage}->[$i]);
        my $systemimage_id = $esystemimage->create(econtext          => $self->{nas}->{econtext},
                              erollback         => $self->{erollback},
                              devs              => $devs,
                              component_storage => $self->{_objs}->{component_storage});
                              
        # Install Component on systemimage
        my $comp_mount_id = Entity::Component->getComponentId(component_name      => "Mounttable",
                                                        component_version   => "1");
                                                        
        $esystemimage->_getEntity()->installedComponentLinkCreation(component_id=>$comp_mount_id);

        # Activate System image
        $esystemimage->activate(econtext          => $self->{nas}->{econtext},
                              erollback         => $self->{erollback},
                              component_export => $self->{_objs}->{component_export});
        

        # Prepare cluster definition
        my $cluster = { cluster_name            => $tier_fullname,
                        cluster_desc            => "This cluster is used for the tier <".$tier->{name}."> of infrastructure <" . $infrastructure_def->{name} .">",
                        cluster_type            => 0,
                        cluster_nameserver      => $local_nameserver,
                        cluster_domainname      => $infrastructure_def->{domain_name},
                        cluster_min_node        => $min_node,
                        cluster_max_node        => $max_node,
                        cluster_priority        => $infrastructure_def->{priority},
                        cluster_si_location     => "diskless",
                        cluster_si_access_mode  => $cluster_si_access_mode,
                        cluster_si_shared       => 1, # always remotely accessed
                        systemimage_id          => $systemimage_id};

        # Prepare tier definition
        my $tmp_tier = {infrastructure_id       => $self->{_objs}->{infrastructure}->getAttr(name=>"infrastructure_id"),
                        tier_name               => $infrastructure_def->{reference} . "_" .$tier->{name},
                        tier_rank               => $tier->{rank},
                        tier_data_src           => $tier->{data}->[0]->{repository},
                        tier_poststart_script   => $tier->{data}->[0]->{init_script}};

        # Cluster instantiation
        $self->{_objs}->{clusters}->[$i] = Entity::ServiceProvider::Inside::Cluster->new(%$cluster);
        # Cluster Activation 
        $self->{_objs}->{clusters}->[$i]->setAttr(name => 'active', value => 1);
        # Save Cluster
        $self->{_objs}->{clusters}->[$i]->save;
        my $ecluster = EFactory::newEEntity(data => $self->{_objs}->{clusters}->[$i]);
        $ecluster->create(econtext => $self->{nas}->{econtext},erollback => $self->{erollback});
        
        $tmp_tier->{cluster_id} = $self->{_objs}->{clusters}->[$i]->getAttr(name=>"cluster_id");
        
        # Tier instanciation
        $self->{_objs}->{tiers}->[$i] = Entity::Tier->new(%$tmp_tier);
        $self->{_objs}->{tiers}->[$i]->save();

        my $dmz_ip_id =  $adm->{manager}->{network}->newDmzIP('ipv4_address' => $tier->{dmz_ip}->{addr},
                                                             'ipv4_mask'    => $tier->{dmz_ip}->{netmask});

        # Set IP
        if ($tier->{rank} == 1) {
            $adm->{manager}->{network}->setClusterPublicIP('publicip_id'   => $public_ip_id,
                                                           'cluster_id'    => $tmp_tier->{cluster_id});
        }
        $adm->{manager}->{network}->setTierDmzIP('dmzip_id'   => $dmz_ip_id,
                                                 'tier_id'    => $self->{_objs}->{tiers}->[$i]->getAttr(name=>"tier_id"));
        
        my $comps = $tier->{component_list};
        # Now foreach tier we will add components to cluster and tier. In the future, component will be only attached to tier
        foreach my $comp (@$comps) {
            my $comp_id = Entity::Component->getComponentId(component_name      => $comp->{name},
                                                            component_version   => $comp->{version});
            # Component instance creation
            my $comp_instance_id = $self->{_objs}->{clusters}->[$i]->addComponent(tier_id      => $self->{_objs}->{tiers}->[$i]->getAttr(name=>"tier_id"),
                                                                                  component_id => $comp_id, noconf => 1);
            my $comp_instance = $self->{_objs}->{clusters}->[$i]->getComponentByInstanceId(component_instance_id => $comp_instance_id);
            # Set component instance configuration from json
            $comp_instance->setConf($comp->{conf});
        }
        
        #insert mountable configuration
        my $comp_mounttable = $self->{_objs}->{clusters}->[$i]->getComponent(name      => "Mounttable",
                                                                             version   => "1");
        my @default_mounttable_conf = (
            {   mounttable1_device  => 'proc', mounttable1_mountpoint => '/proc', mounttable1_filesystem => 'proc',
                mounttable1_options => 'nodev,noexec,nosuid', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
            {   mounttable1_device  => 'sysfs', mounttable1_mountpoint => '/sys', mounttable1_filesystem => 'sysfs',
                mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
            {   mounttable1_device  => 'tmpfs', mounttable1_mountpoint => '/tmp', mounttable1_filesystem => 'tmpfs',
                mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
            {   mounttable1_device  => 'tmpfs', mounttable1_mountpoint => '/var/tmp', mounttable1_filesystem => 'tmpfs',
                mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
            {   mounttable1_device  => 'tmpfs', mounttable1_mountpoint => '/var/run', mounttable1_filesystem => 'tmpfs',
                mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0' },
            {   mounttable1_device  => 'tmpfs', mounttable1_mountpoint => '/var/lock', mounttable1_filesystem => 'tmpfs',
                mounttable1_options => 'defaults', mounttable1_dumpfreq => '0', mounttable1_passnum => '0'},
            {   mounttable1_device  => $self->{nas}->{ip} .":/nfsexports/$disk_name", mounttable1_mountpoint => $tier->{data}->[0]->{mount_point}, mounttable1_filesystem => 'nfs',
                mounttable1_options => 'rw,no_subtree_check,no_root_squash,sync', mounttable1_dumpfreq => '0', mounttable1_passnum => '0'},
        );
        $comp_mounttable->setConf({mounttable_mountdefs => \@default_mounttable_conf});
        
        # Set Monitoring conf
        $log->error("tier collect sets are : $tier->{collector_sets}");
        my @sets = split(/,/, $tier->{collector_sets});
        $adm->{manager}->{monitor}->collectSets(cluster_id => $tmp_tier->{cluster_id},
                                                sets_name => \@sets);
        
        # Set Orchestration conf
        $adm->{manager}->{rules}->addClusterRule(cluster_id     => $tmp_tier->{cluster_id},
                                                 action         => 'add_node',
                                                 condition_tree => [{'operator' => 'inf',
                                                                      'time_laps' => '60',
                                                                       'value' => '70',
                                                                       'var' => 'mem:Total'
                                                                    },
                                                                    '|',
                                                                    {'operator' => 'inf',
                                                                     'time_laps' => '60',
                                                                     'value' => '80',
                                                                     'var' => 'cpu:Idle'
                                                                    }]);
        $adm->{manager}->{rules}->addClusterOptimConditions(cluster_id     => $tmp_tier->{cluster_id},
                                                 action         => 'remove_node',
                                                 condition_tree => [{'operator' => 'sup',
                                                                     'time_laps' => '3600',
                                                                     'value' => '70',
                                                                     'var' => 'mem:Avail'}]);
        $i++;
    }
}


=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;