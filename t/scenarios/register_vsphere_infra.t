#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'RegisterVsphereInfra.t.log', layout=>'%F %L %p %m%n'});

use BaseDB;
use Entity::Component::Vsphere5::Vsphere5Datacenter;
use Entity::Host::Hypervisor::Vsphere5Hypervisor;
use Entity::Host::VirtualMachine::Vsphere5Vm;

use Kanopya::Tools::Create;

# 1) Retrieve (separately for each type) vSphere items
# 2) Register items in Kanopya
# 3) Test number of registered items
# 4) Register again and test no more registration

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

my $vsphere_cluster;
lives_ok {
    $vsphere_cluster = Kanopya::Tools::Create->createCluster(
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
    $vsphere = $vsphere_cluster->getComponent(name => "Vsphere", version => 5);
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
        $datacenter->{children} = $vsphere->retrieveClustersAndHypervisors(
            datacenter_name => $datacenter->{name}
        );
    }
} 'retrieve Cluster and Hypervisors';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        foreach my $datacenterChildren (@{ $datacenter->{children} }) {
            if ($datacenterChildren->{type} eq 'hypervisor') {
                $datacenterChildren->{children} = $vsphere->retrieveHypervisorVms(
                    datacenter_name => $datacenter->{name},
                    hypervisor_uuid => $datacenterChildren->{uuid},
                );
            }
        }
    }
} 'retrieve VMs on Hypervisors (hosted on Datacenter)';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        foreach my $datacenterChildren (@{ $datacenter->{children} }) {
            if ($datacenterChildren->{type} eq 'cluster') {
                $datacenterChildren->{children} = $vsphere->retrieveClusterHypervisors(
                    datacenter_name => $datacenter->{name},
                    cluster_name    => $datacenterChildren->{name},
                );
            }
        }
    }
} 'retrieve Cluster\'s Hypervisors';

lives_ok {
    foreach my $datacenter (@$registerItems) {
        foreach my $datacenterChildren (@{ $datacenter->{children} }) {
            if ($datacenterChildren->{type} eq 'cluster') {
                foreach my $clusterHypervisor (@{ $datacenterChildren->{children} }) {
                    # clusterHypervisors are registered as hypervisors
                    $clusterHypervisor->{type} = 'hypervisor';
                    $clusterHypervisor->{children} = $vsphere->retrieveHypervisorVms(
                        datacenter_name => $datacenter->{name},
                        hypervisor_uuid => $clusterHypervisor->{uuid},
                    );
                }
            }
        }
    }
} 'retrieve VMs on Cluster\'s Hypervisors';

lives_ok {
    $vsphere->register(register_items => $registerItems);
} 'register items in Kanopya';

diag('Search vSphere matches in Kanopya');
my $total_items_nbr = 0;
my $ko_items_nbr    = 0;
foreach my $datacenter (@$registerItems) {
    $total_items_nbr++;
    eval {
        Entity::Component::Vsphere5::Vsphere5Datacenter->find(
            hash => { vsphere5_datacenter_name => $datacenter->{name} }
        );
    };
    if ($@) {
        $ko_items_nbr++;
    }

    foreach my $clusterOrHypervisor (@{ $datacenter->{children} }) {
        if ($clusterOrHypervisor->{type} eq 'cluster') {
            foreach my $hypervisorCluster (@{ $clusterOrHypervisor->{children} }) {
                $total_items_nbr++;
                eval {
                    Entity::Host::Hypervisor::Vsphere5Hypervisor->find(
                        hash => { vsphere5_uuid => $hypervisorCluster->{uuid} }
                    );
                };
                if ($@) {
                    $ko_items_nbr++
                }
                foreach my $vm_vsphere (@{ $hypervisorCluster->{children} }) {
                    $total_items_nbr++;
                    eval {
                        Entity::Host::VirtualMachine::Vsphere5Vm->find(
                            hash => { vsphere5_uuid => $vm_vsphere->{uuid} },
                        );
                    };
                    if ($@) {
                        $ko_items_nbr++;
                    }
                }
            }
        }
        elsif ($clusterOrHypervisor->{type} eq 'hypervisor') {
            $total_items_nbr++;
            foreach my $vm_hypervisor (@{ $clusterOrHypervisor->{children} }) {
                $total_items_nbr++;
                eval {
                    Entity::Host::VirtualMachine::Vsphere5Vm->find(
                        hash => { vsphere5_uuid => $vm_hypervisor->{uuid} },
                    );
                };
                if ($@) {
                    $ko_items_nbr++;
                }
            }
        }
    }
}

is($ko_items_nbr, 0, 'Test number of registered items : ' . ($total_items_nbr - $ko_items_nbr)
    . '/' . $total_items_nbr . ' items registered');

diag('register again items in Kanopya');
eval {
    $vsphere->register(register_items => $registerItems);
};

my $kanopya_items_nbr  =   scalar(@{ Entity::Component::Vsphere5::Vsphere5Datacenter->search(hash => {}) });
$kanopya_items_nbr    +=   scalar(@{ Entity::Host::Hypervisor::Vsphere5Hypervisor->search(hash => {}) });
$kanopya_items_nbr    +=   scalar(@{ Entity::Host::VirtualMachine::Vsphere5Vm->search(hash => {}) });

is($kanopya_items_nbr, $total_items_nbr - $ko_items_nbr, 'Test if no more item is registered');

if ($testing == 1) {
    BaseDB->rollbackTransaction;
}