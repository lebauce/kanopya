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

use Test::More;
use Test::Exception;

use Kanopya::Exceptions;
use General;
use Entity::Host;
use Entity::ServiceProvider::Inside::Cluster;
use Hash::Merge qw(merge);

=pod

=begin classdoc

Create a cluster

@optional cluster_conf override configuration for cluster
@optional components components for the cluster 
@optional managers managers for the cluster 
@optional hosts hosts to be created along the cluster

=end classdoc

=cut

sub createCluster {
    my ($self,%args) = @_;

    my $hosts      = $args{hosts};
    my $components = $args{components};
    my $managers   = $args{managers};
    my $given_conf = $args{cluster_conf};
    my %cluster_conf;

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

    diag('Retrieving NFS server component');
    my $nfs_manager = EEntity->new(
                           entity => $kanopya_cluster->getComponent(name    => "Nfsd",
                                                                    version => 3)
                      );

    diag('Creating disk for image repository');
    my $image_disk = $disk_manager->createDisk(
            name       => "test_image_repository",
            size       => 6 * 1024 * 1024 * 1024,
            filesystem => "ext3",
            vg_id      => 1
    )->_getEntity;

    diag('Creating export for image repository');
    my $nfs = $nfs_manager->createExport(
            container      => $image_disk,
            export_name    => "test_image_repository",
            client_name    => "*",
            client_options => "rw,sync,no_root_squash"
        );

    diag('Get a kernel');
    my $kernel = Entity::Kernel->find(hash => { kernel_name => $ENV{'KERNEL'} || "2.6.32-279.5.1.el6.x86_64" });

    diag('Retrieve the admin user');
    my $admin_user = Entity::User->find(hash => { user_login => 'admin' });

    diag('Deploy master image');
    my $deploy = Entity::Operation->enqueue(
                  priority => 200,
                  type     => 'DeployMasterimage',
                  params   => { file_path => "/vagrant/" . ($ENV{'MASTERIMAGE'} || "centos-6.3-opennebula3.tar.bz2"),
                                keep_file => 1 },
    );
    Kanopya::Tools::Execution->executeOne(entity => $deploy);

    diag('Retrieve master image');
    my $masterimage = Entity::Masterimage->find( hash => { } );

    diag('Retrieve admin NetConf');
    my $adminnetconf   = Entity::Netconf->find(hash => {
        netconf_name    => "Kanopya admin"
    });

    diag('Retrieve iSCSI portals');
    my @iscsi_portal_ids;
    for my $portal (Entity::Component::Iscsi::IscsiPortal->search(hash => { iscsi_id => $export_manager->id })) {
        push @iscsi_portal_ids, $portal->id;
    }

    my %default_conf = (
                           active                => 1,
                           cluster_name          => 'DefaultCluster',
                           cluster_min_node      => 1,
                           cluster_max_node      => 3,
                           cluster_priority      => "100",
                           cluster_si_shared     => 0,
                           cluster_si_persistent => 1,
                           cluster_domainname    => 'my.domain',
                           cluster_basehostname  => 'one',
                           cluster_nameserver1   => '208.67.222.222',
                           cluster_nameserver2   => '127.0.0.1',
                           kernel_id             => $kernel->id,
                           masterimage_id        => $masterimage->id,
                           user_id               => $admin_user->id,
                           managers              => {
                               host_manager => {
                                   manager_id     => $physical_hoster->id,
                                   manager_type   => "host_manager",
                                   manager_params => {
                                       cpu => 1,
                                       ram => 512*1024*1024,
                                   },
                               },
                               disk_manager => {
                                   manager_id     => $disk_manager->id,
                                   manager_type   => "disk_manager",
                                   manager_params => {
                                       vg_id => 1,
                                       systemimage_size => 4 * 1024 * 1024 * 1024,
                                   },
                               },
                               export_manager => {
                                   manager_id     => $export_manager->id,
                                   manager_type   => "export_manager",
                                   manager_params => {
                                       iscsi_portals => \@iscsi_portal_ids,
                                   }
                               },
                           },
                           components => {
                           },
                           interfaces => {
                               public => {
                                   interface_netconfs  => { $adminnetconf->id => $adminnetconf->id },
                               }
                           }
                       );

    if (defined $given_conf) {
        Hash::Merge::set_behavior('RIGHT_PRECEDENT');
        %cluster_conf = %{ merge(\%default_conf, $given_conf) };
    }
    else {
        %cluster_conf = %default_conf;
    }

    my %comps;
    if (defined $components) {
        while (my ($component,$comp_conf) = each %$components) {
            my %tmp = (
                components => {
                    $component => {
                        component_type => ComponentType->find(hash => {
                                               component_name => $component
                                          })->id
                    }
                }
            );
            Hash::Merge::set_behavior('RIGHT_PRECEDENT');
            %comps = %{ merge(\%comps, \%tmp) };
        }
        %cluster_conf = %{ merge(\%cluster_conf, \%comps) };
    }

    my %mgrs;
    if (defined $managers) {
        while (my ($manager,$mgr_conf) = each %$managers) {
            my %tmp = (
                managers => { 
                    $manager => {
                        manager_type => $manager,
                        %$mgr_conf
                    }
                }
            );
            Hash::Merge::set_behavior('RIGHT_PRECEDENT');
            %mgrs = %{ merge(\%mgrs, \%tmp) };
        }
        %cluster_conf = %{ merge(\%cluster_conf, \%mgrs) };
    }

    diag('Create cluster');
    my $cluster_create = Entity::ServiceProvider::Inside::Cluster->create(%cluster_conf);

    if (defined $hosts) {
        diag('Registering physical hosts');
        foreach my $host (@{ $hosts }) {
            Kanopya::Tools::Register->registerHost(board => $host);
        }
    }

    Kanopya::Tools::Execution->executeOne(entity => $cluster_create);
}

=pod

=begin classdoc

Create a cluster of VMs

@param iaas the cluster of hypervisors to be used for the vm's cluster

=end classdoc

=cut
sub createVMcluster {

}

1;
