#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;     
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'ScaleVsphereInfra.t.log', layout=>'%F %L %p %m%n'});

use_ok ('Administrator');
use_ok ('Executor');
use_ok ('EFactory');
use_ok ('Entity::ServiceProvider::Inside::Cluster');
use_ok ('Entity::User');
use_ok ('Entity::Kernel');
use_ok ('Entity::Processormodel');
use_ok ('Entity::Hostmodel');
use_ok ('Entity::Masterimage');
use_ok ('Entity::Network');
use_ok ('Entity::Poolip');
use_ok ('Entity::Host');
use_ok ('Entity::Operation');
use_ok ('Entity::Container');
use_ok ('Entity::ContainerAccess');
use_ok ('Entity::ContainerAccess::NfsContainerAccess');
use_ok ('Externalnode::Node');
use_ok ('ComponentType');
use_ok ('Entity::InterfaceRole');

my $testing = 0;
my $vsphere_url = '192.168.2.160';
my $vm_name = 'random1';
my $scale_memory_value = 2048 * 1024 * 1024;
my $scale_cpu_value = 2;

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    my @args = ();
    my $executor = new_ok("Executor", \@args, "Instantiate an executor");

    my $admin_user;
    lives_ok {
        $admin_user = Entity::User->find(hash => { user_login => 'admin' });
    } 'Retrieve the admin user';

    diag('Register, Retrieve and Configure vSphere Component');
    my $cluster;
    lives_ok {
        $cluster = Entity::ServiceProvider::Inside::Cluster->new(
            active                 => 1,
            cluster_name           => "VSphere",
            cluster_min_node       => "1",
            cluster_max_node       => "3",
            cluster_priority       => "100",
            cluster_si_shared      => 0,
            cluster_si_persistent  => 1,
            cluster_domainname     => 'my.domain',
            cluster_basehostname   => 'one',
            cluster_nameserver1    => '208.67.222.222',
            cluster_nameserver2    => '127.0.0.1',
            user_id                => $admin_user->id,
        );
      } 'Register VSphere cluster';

    isa_ok($cluster, 'Entity::ServiceProvider::Inside::Cluster');

    my $vsphereInstance;
    lives_ok {
        $vsphereInstance = $cluster->addComponentFromType(
                               component_type_id => ComponentType->find(hash => {
                                                        component_name => 'Vsphere'})->id,
                           );
    } 'Register Vsphere component';

    isa_ok($vsphereInstance, 'Entity::Component::Vsphere5');

    my $vsphere;
    lives_ok {
        $vsphere = $cluster->getComponent(name    => "Vsphere",
                                          version => 5);
    } 'Retrieve Vsphere component';

    isa_ok($vsphere, 'Entity::Component::Vsphere5');

    lives_ok {
        $vsphere->setConf(
            conf => {
                vsphere5_login    => 'Administrator@hedera.forest',
                vsphere5_pwd      => 'H3d3r4#234',
                vsphere5_url      => $vsphere_url,
            }
        );
    } 'Configure VSphere component';

    diag('Retrieve and Register vSphere infrastructure');
    my $registerItems;
    lives_ok {
        my $datacenters = $vsphere->retrieveDatacenters();
        $registerItems  = $datacenters;
    } 'Retrieve Datacenters';

    lives_ok {
        foreach my $datacenter (@$registerItems) {
            my $clustersAndHypervisors = $vsphere->retrieveClustersAndHypervisors(
                                             datacenter_name => $datacenter->{name}
                                         );
            $datacenter->{children}    = $clustersAndHypervisors;
        }
    } 'Retrieve Cluster and Hypervisors';

    lives_ok {
        foreach my $datacenter (@$registerItems) {
            foreach my $datacenterChildren (@{ $datacenter->{children} }) {
                if ($datacenterChildren->{type} eq 'hypervisor') {
                    my $vms = $vsphere->retrieveHypervisorVms(
                                  datacenter_name => $datacenter->{name},
                                  hypervisor_name => $datacenterChildren->{name},
                              );
                    $datacenterChildren->{children} = $vms;
                }
            }
        }
    } 'Retrieve VMs on Hypervisors (hosted on Datacenter)';

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
    } 'Retrieve Cluster\'s Hypervisors';

    lives_ok {
        foreach my $datacenter (@$registerItems) {
            foreach my $datacenterChildren (@{ $datacenter->{children} }) {
                if ($datacenterChildren->{type} eq 'cluster') {
                    foreach my $clusterHypervisor (@{ $datacenterChildren->{children} }) {
                        #Change type 'clusterHypervisor' to 'hypervisor'
                        $clusterHypervisor->{type} = 'hypervisor';
                        my $vms = $vsphere->retrieveHypervisorVms(
                                      datacenter_name => $datacenter->{name},
                                      hypervisor_name => $clusterHypervisor->{name},
                                  );
                        $clusterHypervisor->{children} = $vms;
                    }
                }
            }
        }
    } 'Retrieve VMs on Cluster\'s Hypervisors';

    lives_ok {
        my $registered_items = $vsphere->register(register_items => $registerItems);
    } 'Register items in Kanopya';

    my $total_items_nbr = 0;
    my $ko_items_nbr    = 0;
    lives_ok {
        foreach my $datacenter_vsphere (@$registerItems) {
            $total_items_nbr++;
            eval {
                my $datacenter_kanopya = Vsphere5Datacenter->find(
                                             hash => {vsphere5_datacenter_name => $datacenter_vsphere->{name}}
                                         );
            };
            if ($@) {
                $ko_items_nbr++;
            }

            foreach my $clusterOrHypervisor_vsphere (@{ $datacenter_vsphere->{children} }) {
                $total_items_nbr++;
                eval {
                    (my $clusterOrHypervisor_vsphere_renamed = $clusterOrHypervisor_vsphere->{name}) =~ s/[^\w\d]/_/g;
                    my $clusterOrHypervisor_kanopya = Entity::ServiceProvider::Inside::Cluster->find(
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
                            my $vm_hypervisor_vsphere_kanopya = Entity::ServiceProvider::Inside::Cluster->find(
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
                                my $vm_kanopya = Entity::ServiceProvider::Inside::Cluster->find(
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
    } 'Search vSphere matches in Kanopya';

    is($ko_items_nbr, 0,'Test number of registered items : '.($total_items_nbr - $ko_items_nbr).'/'.$total_items_nbr.' items registered');

    lives_ok {
        my $registered_items = $vsphere->register(register_items => $registerItems);
    } 'Register again items in Kanopya';

    my $kanopya_items_nbr = 0;
    lives_ok {
        my $unwanted_items_nbr = 2;#Unwanted items (cluster Kanopya and cluster on which component is installed)
        $kanopya_items_nbr     =   scalar(Vsphere5Datacenter->search(hash => {}));
        $kanopya_items_nbr    +=   scalar(Entity::ServiceProvider::Inside::Cluster->search(hash => {}));
        $kanopya_items_nbr    -=   $unwanted_items_nbr;
    } 'Get Kanopya items number';

    is($kanopya_items_nbr, $total_items_nbr - $ko_items_nbr, 'Test if no more item is registered');

    diag('Scale in Memory');
    my $vm_host;
    lives_ok {
        my @vm_cluster_nodes = Entity::ServiceProvider::Inside::Cluster->find(hash => {'cluster_name' => $vm_name})->nodes;
        $vm_host             = $vm_cluster_nodes[0]->host;#each cluster contains only 1 item
    } 'Retrieve Virtual Machine host from Kanopya';

    lives_ok {
        my $workflow = $vm_host->scale(
                           'scalein_value'    =>    $scale_memory_value,
                           'scalein_type'     =>    'memory',
                       );
        execWorkflow($workflow, $executor);
    } 'Scale memory for host retrieved';

    lives_ok {
        $vm_host = Entity::Host::VirtualMachine::Vsphere5Vm->get(id => $vm_host->id);
    } 'Refresh Virtual Machine entity';

    is($vm_host->host_ram, $scale_memory_value, 'Test if scale memory went well');

    diag('Scale in CPU');
    lives_ok {
        my $workflow = $vm_host->scale(
                           'scalein_value'    =>    $scale_cpu_value,
                           'scalein_type'     =>    'cpu',
                       );
        execWorkflow($workflow, $executor);
    } 'Scale cpu for host retrieved';

    lives_ok {
        $vm_host = Entity::Host::VirtualMachine::Vsphere5Vm->get(id => $vm_host->id);
    } 'Refresh Virtual Machine entity';

    is($vm_host->host_core, $scale_cpu_value, 'Test if scale CPU went well');

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
};

if($@) {
    my $error = $@; 
    print $error."\n";
}

sub execWorkflow {
    my ($workflow, $executor) = @_;
    my $workflow_id = $workflow->id;
    my $test = 'Scale in went successfully';
    WAITSCALE:
    while(1) {
        $workflow = Entity::Workflow->get(id => $workflow_id);
	    my $state = $workflow->state;
	    if($state eq 'running') {
            $executor->oneRun;
    	    next WAITSCALE;
	    }
        elsif($state eq 'done') {
		    pass($test);
		    last WAITSCALE;
	    }
        elsif($state eq 'failed') {
		    fail($test);
		    last WAITSCALE;
	    }
    }
}
