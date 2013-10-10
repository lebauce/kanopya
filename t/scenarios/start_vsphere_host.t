#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'start_vsphere_host.t.log', layout=>'%F %L %p %m%n'});

use Kanopya::Database;
use Kanopya::Tools::Execution;
use Kanopya::Tools::Create;

# 1) Create a Iaas Cluster of vSphere type
# 2) Register a vSphere infrastructure
# 3) Create NFS and diskless Vms clusters which use the Iaas host manager
# 4) Start the Vms clusters

my $testing = 0;

my $vsphere_conf = {
    vsphere5_login               => 'Administrator',
    vsphere5_pwd                 => 'Hedera@123',
    vsphere5_url                 => '192.168.2.147',
    overcommitment_cpu_factor    => 10,
};

Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

if ($testing == 1) {
    Kanopya::Database::beginTransaction;
}

diag('Register master image');
my $masterimage;
lives_ok {
    $masterimage = Kanopya::Tools::Register::registerMasterImage();
} 'Register master image';

diag('Create a Iaas cluster holding vSphere component');
my $vsphere_cluster;
lives_ok{
    $vsphere_cluster = Kanopya::Tools::Create->createIaasCluster(
                              iaas_type    => 'vsphere',
                              vsphere_conf => $vsphere_conf,
                              cluster_conf => {
                                  cluster_name         => 'VSphere',
                                  cluster_basehostname => 'vsphere',
                                  masterimage_id       => $masterimage->id,
                              },
                          );
} 'Create vSphere IaaS cluster';

diag('Register vSphere infrastructure');
lives_ok {
    my $vsphere = $vsphere_cluster->getComponent(name => 'Vsphere');

    # retrieve items
    my $vsphere_items = $vsphere->retrieveDatacenters();
    foreach my $datacenter (@$vsphere_items) {
        $datacenter->{children} = $vsphere->retrieveClustersAndHypervisors (
            datacenter_name => $datacenter->{name},
        );
        foreach my $cluster_or_hypervisor (@{ $datacenter->{children} }) {
            if ($cluster_or_hypervisor->{type} eq 'cluster') {
                $cluster_or_hypervisor->{children} = $vsphere->retrieveClusterHypervisors(
                    datacenter_name => $datacenter->{name},
                    cluster_name    => $cluster_or_hypervisor->{name},
                );
                foreach my $cluster_hypervisor (@{ $cluster_or_hypervisor->{children} }) {
                    $cluster_hypervisor->{type} = 'hypervisor';
                    $cluster_hypervisor->{children} = $vsphere->retrieveHypervisorVms(
                        datacenter_name => $datacenter->{name},
                        hypervisor_uuid => $cluster_hypervisor->{uuid},
                    );
                }
            }
            elsif ($cluster_or_hypervisor->{type} eq 'hypervisor') {
                $cluster_or_hypervisor->{children} = $vsphere->retrieveHypervisorVms(
                    datacenter_name => $datacenter->{name},
                    hypervisor_uuid => $cluster_or_hypervisor->{uuid},
                );
            }
        }
    }

    # register items
    $vsphere->register(register_items => $vsphere_items);
} 'Register vSphere infrastructure';

diag('Create diskless vms cluster with vSphere cluster as host manager');
my $diskless_vm_cluster;
lives_ok{
    $diskless_vm_cluster = Kanopya::Tools::Create->createVmCluster(
                               iaas           => $vsphere_cluster,
                               container_type => 'iscsi',
                               cluster_conf => {
                                   cluster_name         => 'VSphereDisklessVMs',
                                   cluster_basehostname => 'vsphere-diskless',
                                   masterimage_id       => $masterimage->id,
                               },
                           );
} 'Create Diskless VMs cluster';

diag('Create NFS vms cluster with vSphere cluster as host manager');
my $nfs_vm_cluster;
lives_ok{
    $nfs_vm_cluster = Kanopya::Tools::Create->createVmCluster(
                          iaas => $vsphere_cluster,
                          container_type => 'nfs',
                          cluster_conf => {
                              cluster_name         => 'VSphereNfsVMs',
                              cluster_basehostname => 'vsphere-nfs',
                              masterimage_id       => $masterimage->id,
                          },
                      );
    $nfs_vm_cluster->addManagerParameters(
        manager_type => 'DiskManager',
        params => {
            image_type => 'vmdk'
        }
    );
} 'Create NFS VMs cluster';

diag('Start Diskless VM cluster');
lives_ok{
    Kanopya::Tools::Execution->startCluster(cluster => $diskless_vm_cluster);
} 'Start Diskless VM cluster';

diag('Start NFS VM cluster');
lives_ok{
    Kanopya::Tools::Execution->startCluster(cluster => $nfs_vm_cluster);
} 'Start NFS VM cluster';

if ($testing == 1) {
    Kanopya::Database::rollbackTransaction;
}