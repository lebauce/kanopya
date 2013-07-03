#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'RegisterVsphereInfra.t.log', layout=>'%F %L %p %m%n'});

use BaseDB;
use Entity::ServiceProvider::Cluster;
use Entity::Component::Vsphere5::Vsphere5Datacenter;

use Kanopya::Tools::Create;

my $testing = 0;

my $vsphere_conf = {
    vsphere5_login => 'Administrator',
    vsphere5_pwd   => 'Hedera@123',
    vsphere5_url   => '192.168.2.147',
};

BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

if ($testing == 1) {
    BaseDB->beginTransaction;
}

my $cluster;
lives_ok {
    $cluster = Kanopya::Tools::Create->createCluster(
                    cluster_conf => {
                        cluster_name         => 'VSphere',
                        cluster_basehostname => 'vsphere'
                    },
                    components => {
                        'vsphere' => {
                            overcommitment_cpu_factor    => 1,
                            overcommitment_memory_factor => 1
                        },
                    }
               );
} 'Register VSphere cluster';

my $vsphere;
lives_ok {
    $vsphere = $cluster->getComponent(name => "Vsphere", version => 5);
} 'retrieve Vsphere component';

lives_ok {
    $vsphere->setConf(conf => $vsphere_conf);
} 'configuring VSphere component';

my $registerItems;
lives_ok {
    $registerItems  = $vsphere->retrieveDatacenters();
} 'retrieve Datacenters';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        my $clustersAndHypervisors = $vsphere->retrieveClustersAndHypervisors(
                                         datacenter_name => $datacenter->{name}
                                     );
        $datacenter->{children}    = $clustersAndHypervisors;
    }
} 'retrieve Cluster and Hypervisors';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        foreach my $datacenterChildren (@{ $datacenter->{children} }) {
            if ($datacenterChildren->{type} eq 'hypervisor') {
                my $vms = $vsphere->retrieveHypervisorVms(
                              datacenter_name => $datacenter->{name},
                              hypervisor_uuid => $datacenterChildren->{uuid},
                          );
                $datacenterChildren->{children} = $vms;
            }
        }
    }
} 'retrieve VMs on Hypervisors (hosted on Datacenter)';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        foreach my $datacenterChildren (@{ $datacenter->{children} }) {
            if ($datacenterChildren->{type} eq 'cluster') {
                my $clusterHypervisors = $vsphere->retrieveClusterHypervisors(
                                             datacenter_name => $datacenter->{name},
                                             cluster_name    => $datacenterChildren->{name},
                                         );
                $datacenterChildren->{children} = $clusterHypervisors;
            }
        }
    }
} 'retrieve Cluster\'s Hypervisors';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        foreach my $datacenterChildren (@{ $datacenter->{children} }) {
            if ($datacenterChildren->{type} eq 'cluster') {
                foreach my $clusterHypervisor (@{ $datacenterChildren->{children} }) {
                    #Change type 'clusterHypervisor' to 'hypervisor'
                    $clusterHypervisor->{type} = 'hypervisor';
                    my $vms = $vsphere->retrieveHypervisorVms(
                                  datacenter_name => $datacenter->{name},
                                  hypervisor_uuid => $clusterHypervisor->{uuid},
                              );
                    $clusterHypervisor->{children} = $vms;
                }
            }
        }
    }
} 'retrieve VMs on Cluster\'s Hypervisors';

lives_ok {
    my $registered_items = $vsphere->register(register_items => $registerItems);
} 'register items in Kanopya';

# TODO : refresh retrieval
diag('Search vSphere matches in Kanopya');
my $total_items_nbr = 0;
my $ko_items_nbr    = 0;
foreach my $datacenter_vsphere (@$registerItems) {
    $total_items_nbr++;
    eval {
        my $datacenter_kanopya = Entity::Component::Vsphere5::Vsphere5Datacenter->find(
                                     hash => { vsphere5_datacenter_name => $datacenter_vsphere->{name} }
                                 );
    };
    if ($@) {
        $ko_items_nbr++;
    }

    foreach my $clusterOrHypervisor_vsphere (@{ $datacenter_vsphere->{children} }) {
        $total_items_nbr++;
        eval {
            (my $clusterOrHypervisor_vsphere_renamed = $clusterOrHypervisor_vsphere->{name}) =~ s/[^\w\d]/_/g;
            my $clusterOrHypervisor_kanopya = Entity::ServiceProvider::Cluster->find(
                                                  hash => {cluster_name => $clusterOrHypervisor_vsphere_renamed},
                                              );
        };
        if ($@) {
            $ko_items_nbr++;
        }

        if ($clusterOrHypervisor_vsphere->{type} eq 'hypervisor') {
            foreach my $vm_hypervisor_vsphere (@{ $clusterOrHypervisor_vsphere->{children} }) {
                $total_items_nbr++;
                eval {
                    (my $vm_hypervisor_vsphere_renamed = $vm_hypervisor_vsphere->{name}) =~ s/[^\w\d]/_/g;
                    my $vm_hypervisor_vsphere_kanopya = Entity::ServiceProvider::Cluster->find(
                                                            hash => {cluster_name => $vm_hypervisor_vsphere_renamed},
                                                        );
                };
                if ($@) {
                    $ko_items_nbr++;
                }
            }
        }
        elsif ($clusterOrHypervisor_vsphere->{type} eq 'cluster') {
            foreach my $hypervisorCluster_vsphere (@{ $clusterOrHypervisor_vsphere->{children} }) {
                foreach my $vm_vsphere (@{ $hypervisorCluster_vsphere->{children} }) {
                    $total_items_nbr++;
                    eval {
                        (my $vm_vsphere_renamed = $vm_vsphere->{name}) =~ s/[^\w\d]/_/g;
                        my $vm_kanopya = Entity::ServiceProvider::Cluster->find(
                                             hash => {cluster_name => $vm_vsphere_renamed},
                                         );
                    };
                    if ($@) {
                        $ko_items_nbr++;
                    }
                }
            }
        }
    }
}

is($ko_items_nbr, 0, 'Test number of registered items : ' . ($total_items_nbr - $ko_items_nbr)
    . '/' . $total_items_nbr . ' items registered');

lives_ok {
    my $registered_items = $vsphere->register(register_items => $registerItems);
} 'register again items in Kanopya';

diag('get Kanopya items number');
my $kanopya_items_nbr = 0;
my $unwanted_items_nbr = 2;#Unwanted items (cluster Kanopya and cluster on which component is installed)
$kanopya_items_nbr     =   scalar(@{ Entity::Component::Vsphere5::Vsphere5Datacenter->search(hash => {}) });
$kanopya_items_nbr    +=   scalar(@{ Entity::ServiceProvider::Cluster->search(hash => {}) });
$kanopya_items_nbr    -=   $unwanted_items_nbr;

is($kanopya_items_nbr, $total_items_nbr - $ko_items_nbr, 'Test if no more item is registered');

if ($testing == 1) {
    BaseDB->rollbackTransaction;
}