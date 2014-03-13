# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

Kanopya module to create items 

@since 13/12/12
@instance hash
@self $self

=end classdoc

=cut

package Kanopya::Tools::Create;

use strict;
use warnings;

use Switch;
use Test::More;
use Test::Exception;
use Hash::Merge;

use Kanopya::Exceptions;
use General;
use NetconfPoolip;
use Entity::Poolip;
use Entity::NetconfRole;
use Entity::Netconf;
use Entity::Host;
use Entity::Container;
use Entity::ContainerAccess::NfsContainerAccess;
use Entity::ServiceProvider::Cluster;
use ClassType::ComponentType;
use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use EEntity;

my $merge = Hash::Merge->new('RIGHT_PRECEDENT');
$merge->specify_behavior( {
    'SCALAR' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { [ $_[0], @{$_[1]} ] },
        'HASH'   => sub { $_[1] },
    },
    'ARRAY' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { [ @{$_[1]} ] },
        'HASH'   => sub { $_[1] },
    },
    'HASH' => {
        'SCALAR' => sub { $_[1] },
        'ARRAY'  => sub { [ values %{$_[0]}, @{$_[1]} ] },
        'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
    },
} );

=pod

=begin classdoc

Create a cluster

@optional cluster_conf override configuration for cluster
@optional components components for the cluster 
@optional managers managers for the cluster 
@optional hosts hosts to be created along the cluster

@warning cluster_basehostname use cluster_name

=end classdoc

=cut

sub createCluster {
    my ($self,%args) = @_;

    my $components     = $args{components};
    my $interfaces     = $args{interfaces};
    my $managers       = $args{managers};
    my $cluster_conf;

    diag('Retrieve the Kanopya cluster');
    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();

    diag('Get physical hoster');
    my $physical_hoster = $kanopya_cluster->getHostManager();

    diag('Retrieving LVM disk manager');
    my $disk_manager = EEntity->new(
                           entity => $kanopya_cluster->getComponent(name    => "Lvm",
                                                                    version => 2)
                       );

    diag('Retrieving iSCSI component');
    my $export_manager = EEntity->new(
                             entity => $kanopya_cluster->getComponent(name    => "Iscsitarget",
                                                                      version => 1)
                         );

    diag('Retrieve the admin owner_id');
    if (not defined $args{owner_id}) {
        $args{owner_id} = Entity::User->find(hash => { user_login => 'admin' })->id;
    }

    diag('Retrieve admin NetConf');
    my $adminnetconf   = Entity::Netconf->find(hash => {
        netconf_name    => "Kanopya admin"
    });

    diag('Retrieve iSCSI portals');
    my @iscsi_portal_ids;
    for my $portal (IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    my $service_template_id;
    eval {
        $service_template_id = Entity::ServiceTemplate->find(hash => { service_name => "Generic service" })->id;
    };

    my $default_conf = {
        active                => 1,
        cluster_name          => 'DefaultCluster',
        cluster_min_node      => 1,
        cluster_max_node      => 3,
        cluster_priority      => "100",
        cluster_si_persistent => 1,
        cluster_domainname    => 'my.domain',
        cluster_nameserver1   => '208.67.222.222',
        cluster_nameserver2   => '127.0.0.1',
        cluster_basehostname  => 'default',
        owner_id              => $args{owner_id},
        default_gateway_id    => ($adminnetconf->poolips)[0]->network->id,
        service_template_id   => $service_template_id,
        managers              => {
            host_manager => {
                manager_id     => $physical_hoster->id,
                manager_type   => "HostManager",
                    manager_params => {
                        cpu => 1,
                        ram => 2*1024*1024,
                    },
                },
            disk_manager => {
                manager_id     => $disk_manager->id,
                manager_type   => "DiskManager",
                manager_params => {
                    vg_id => 1,
                    systemimage_size => 4 * 1024 * 1024 * 1024,
                },
            },
            export_manager => {
                manager_id     => $export_manager->id,
                manager_type   => "ExportManager",
                manager_params => {
                    iscsi_portals => \@iscsi_portal_ids,
                }
            },
        },
        components => {},
        interfaces => {}
    };

    if (defined $args{cluster_conf}) {
        $cluster_conf = $merge->merge($default_conf, $args{cluster_conf});
    }
    else {
        $cluster_conf = $default_conf;
    }

    my $comps;
    if (defined $components) {
        while (my ($component,$comp_conf) = each %$components) {
            my $tmp = {
                components => {
                    $component => {
                        component_type => ClassType::ComponentType->find(hash => {
                                               component_name => $component
                                          })->id,
                        component_configuration => $comp_conf
                    }
                }
            };
            $comps = $merge->merge($comps, $tmp);
        }
        $cluster_conf = $merge->merge($cluster_conf, $comps);
    }

    my $mgrs;
    if (defined $managers) {
        while (my ($manager,$mgr_conf) = each %$managers) {
            my $tmp = {
                managers => { 
                    $manager => {
                        manager_type => General::normalizeName($manager),
                        %$mgr_conf
                    }
                }
            };
            $mgrs = $merge->merge($mgrs, $tmp);
        }
        $cluster_conf = $merge->merge($cluster_conf, $mgrs);
    }

    if (defined $interfaces) {
        my $ifcs = { interfaces => $interfaces };
        $cluster_conf = $merge->merge($cluster_conf, $ifcs);
    }
    else {
        $cluster_conf->{interfaces}->{admin} = {
            interface_name => 'eth0',
            netconfs  => { $adminnetconf->id => $adminnetconf->id },
        };
    }

    diag('Create cluster');
    my $cluster_create = Entity::ServiceProvider::Cluster->create(%$cluster_conf);

    Kanopya::Tools::Execution->executeOne(entity => $cluster_create);

    return Kanopya::Tools::Retrieve->retrieveCluster(criteria => { cluster_name => $cluster_conf->{cluster_name} });
}

=pod

=begin classdoc

Create a cluster of VMs

@param iaas the cluster of hypervisors to be used for the vm's cluster

=end classdoc

=cut

sub createVmCluster {
    my ($self,%args) = @_;

    General::checkParams(
        args => \%args,
        required => ['iaas'],
        optional => {
            'container_name' => 'test_image_repository',
            'container_type' => 'nfs',
            'managers'       => { }
        }
    );

    #get iaas HostManager component to use it as host manager
    my $iaas = $args{iaas};
    my $host_manager = $iaas->getComponent(category => 'HostManager');

    my $kanopya = Kanopya::Tools::Retrieve->retrieveCluster();

    my $managers = {
        host_manager => {
            manager_id     => $host_manager->id,
            manager_params => {
                core     => 2,
                ram      => 512 * 1024 * 1024,
                max_core => 2,
                max_ram  => 1024 * 1024 * 1024,
                ifaces   => 1,
            },
        }
    };

    my $container_type = $args{container_type};
    if ($container_type eq 'nfs') {
        my $container_name = $args{container_name};

        #get fileimagemanager from kanopya cluster as export and disk manager
        my $fileimagemanager = $kanopya->getComponent(name    => "Fileimagemanager",
                                                      version => 0);

        my $nfs = Kanopya::Tools::Retrieve->retrieveContainerAccess(
                      name => $container_name,
                      type => $container_type,
                  );

        $managers->{disk_manager} = {
            manager_id => $fileimagemanager->id,
            manager_params => {
                container_access_id => $nfs->id ,
                systemimage_size    => 4 * 1024 * 1024 * 1024,
            },
        };
        $managers->{export_manager} = {
            manager_id => $fileimagemanager->id,
            manager_params => {
                container_access_id => $nfs->id ,
                systemimage_size    => 4 * 1024 * 1024 * 1024,
            },
        };
    }

    $managers = $merge->merge($managers, $args{managers});
                        
    delete $args{iaas};
    delete $args{container_name};
    delete $args{container_type};
    delete $args{managers};

    return $self->createCluster(
        %args,
        managers => $managers
    );
}

=pod

=begin classdoc

Create a iaas cluster. This function does provide the facility of giving a bridge interface to the cluster
call createCluster() with an admin interface an a single bridge interface

@optional interfaces

=end classdoc

=cut

sub createIaasCluster {
    my ($self, %args) = @_;

    General::checkParams(args     => \%args,
                         required => ['iaas_type'],
                         optional => {
                             'datastores'  => ['system_datastore', 'test_image_repository'],
                         } );

    my $iaas_type = delete $args{iaas_type};

    if ($iaas_type eq 'vsphere') {
        General::checkParams(args     => \%args,
                             required => ['vsphere_conf'],
                            );
    }

    my $kanopya_cluster = Kanopya::Tools::Retrieve->retrieveCluster();

    my $disk_manager = EEntity->new(
                           entity => $kanopya_cluster->getComponent(name => "Lvm")
                       );

    my $nfs_manager = EEntity->new(
                          entity => $kanopya_cluster->getComponent(name => "Nfsd")
                      );

    for my $datastore (@{ $args{datastores} }) {
        eval { Entity::Container->find(hash => {container_name => $datastore}); };
        next if ! $@;

        my $disk = $disk_manager->createDisk(
                       name         => $datastore,
                       size         => 20 * 1024 * 1024 * 1024,
                       filesystem   => "ext4",
                       vg_id        => 1
                   )->_entity;

        my $nfs = $nfs_manager->createExport(
                      container      => $disk,
                      export_name    => $datastore,
                      client_name    => "*",
                      client_options => "rw,sync,no_root_squash"
                  );
    }

    #get vms netconf
    my $admin_poolip = Entity::Poolip->find(hash => { poolip_name => 'kanopya_admin' });
    my $vms_role = Entity::NetconfRole->find(hash => { netconf_role_name => "vms" });
    my $vms_netconf = Entity::Netconf->create(netconf_name    => "vms",
                                              netconf_role_id => $vms_role->id);

    NetconfPoolip->new(netconf_id => $vms_netconf->id,
                       poolip_id  => $admin_poolip->id);

    my $components;
    my $masterimage_id;
    switch ($iaas_type) {
        case 'opennebula' {
            $components =
                {
                    opennebula       => {},
                    kvm              => {},
                    fileimagemanager => {},
                };
            if (not defined $args{cluster_conf}{masterimage_id}) {
                $masterimage_id = Kanopya::Tools::Register::registerMasterImage()->id;
            }
            else {
                $masterimage_id = $args{cluster_conf}{masterimage_id};
            }
        }
        case 'openstack' {
            $components =
                {
                    novaController => {
                        overcommitment_memory_factor => 1,
                        overcommitment_cpu_factor    => 1,
                    },
                    mysql          => {},
                    novaCompute    => {},
                    keystone       => {},
                    neutron        => {},
                    glance         => {},
                    amqp           => {},
                };
            if (not defined $args{cluster_conf}{masterimage_id}) {
                $masterimage_id = Kanopya::Tools::Register::registerMasterImage(
                                   'sles-11-simple-host.tar.bz2'
                )->id;
            }
            else {
                $masterimage_id = $args{cluster_conf}{masterimage_id};
            }
        }
        case 'vsphere' {
            $components = { vsphere => {}, };
            if (not defined $args{cluster_conf}{masterimage_id}) {
                $masterimage_id = Kanopya::Tools::Register::registerMasterImage()->id;
            }
            else {
                $masterimage_id = $args{cluster_conf}{masterimage_id};
            }
        }
    }

    my $cluster_conf = {
        components => $components,
        interfaces => {
            vms => {
                interface_name => 'eth0',
                netconfs => {
                    $vms_netconf->id => $vms_netconf->id
                }
            }
        },
        %args
    };

    $cluster_conf->{masterimage_id} = $masterimage_id;

    my $iaas = $self->createCluster(%$cluster_conf);

    my $system_datastore = Kanopya::Tools::Retrieve->retrieveContainerAccess(
                               name => 'system_datastore',
                               type => 'nfs'
                           );
    my $test_image_repository = Kanopya::Tools::Retrieve->retrieveContainerAccess(
                                    name => 'test_image_repository',
                                    type => 'nfs'
                                );

    my $virtualization;
    my $vmm;
    my $db;
    switch ($iaas_type) {
        case 'opennebula' {
            $virtualization = $iaas->getComponent(name => 'Opennebula');
            $vmm = $iaas->getComponent(name => "Kvm");

            $vmm->setConf(conf => {
                iaas_id => $virtualization->id,
            } );

            $virtualization->setConf(conf => {
                image_repository_path    => "/srv/cloud/images",
                opennebula3_repositories => [ {
                    container_access_id  => $test_image_repository->id,
                    repository_name      => 'image_repo'
                }, {
                    container_access_id  => $system_datastore->id,
                    repository_name      => 'system'
                } ],
                hypervisor               => "kvm"
            } );
        }
        case 'openstack' {
            $virtualization =  $iaas->getComponent(name => 'NovaController');
            $vmm = $iaas->getComponent(name => 'NovaCompute');
            $db = $iaas->getComponent(name => 'Mysql');

            my $amqp = $iaas->getComponent(name => 'Amqp');
            my $keystone = $iaas->getComponent(name => 'Keystone');
            my $glance = $iaas->getComponent(name => 'Glance');
            my $neutron = $iaas->getComponent(name => 'Neutron');

            $keystone->setConf(conf => {
                mysql5_id   => $db->id,
             });

            $glance->setConf(conf => {
                mysql5_id          => $db->id,
                nova_controller_id => $virtualization->id,
            });

            $neutron->setConf(conf => {
                mysql5_id          => $db->id,
                nova_controller_id => $virtualization->id,
            });
            
            $vmm->setConf(conf => {
                nova_controller_id => $virtualization->id,
                iaas_id            => $virtualization->id,
                mysql5_id          => $db->id,
            });

            $virtualization->setConf(conf => {
                mysql5_id    => $db->id,
                keystone_id  => $keystone->id,
                amqp_id      => $amqp->id,
                repositories => [ {
                    container_access_id  => $test_image_repository->id,
                    repository_name      => 'image_repo'
                } ],
            } );
        }
        case 'vsphere' {
            my $vsphere = $iaas->getComponent(name => 'Vsphere');

            $vsphere->setConf(conf =>
                $args{vsphere_conf},
            );
        }
    }

    return $iaas;
}

1;
