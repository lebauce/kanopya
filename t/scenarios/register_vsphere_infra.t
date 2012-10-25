#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;     
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'/tmp/VSphere.t.log', layout=>'%F %L %p %m%n'});

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

my $testing = 1;

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
            # cluster_boot_policy    => 'PXE Boot via ISCSI',
            user_id                => $admin_user->getAttr(name => 'user_id'),
        );
      } 'Register VSphere cluster';


    my $vsphereInstance;
    lives_ok {
        $vsphereInstance = $cluster->addComponentFromType(
                               component_type_id => ComponentType->find(hash => {component_name => 'Vsphere'})->id,
                           );
    } 'register Vsphere component';

    isa_ok($vsphereInstance, 'Entity::Component::Vsphere5');

    my $vsphere;
    lives_ok {
        $vsphere = $cluster->getComponent(name    => "Vsphere",
                                          version => 5);
    } 'retrieve Vsphere component';

    isa_ok($vsphere, 'Entity::Component::Vsphere5');

    lives_ok {
        $vsphere->setConf(conf => {
            vsphere5_login    => 'Administrator@hedera.forest',
            vsphere5_pwd => 'H3d3r4#234',
            vsphere5_url      => '192.168.1.160',
            repositories => { }
        });
    } 'configuring VSphere component';

    my $registerItems;
    lives_ok {
        my $datacenters = $vsphere->retrieveDatacenters();
        $registerItems = $datacenters;
    } 'retrieve Datacenters';

    lives_ok {
        foreach my $datacenter ( @$registerItems ) {
            my $clustersAndHypervisors = $vsphere->retrieveClustersAndHypervisors(datacenter_name => $datacenter->{name});
            $datacenter->{children} = $clustersAndHypervisors;
        }
    } 'retrieve Cluster and Hypervisors';

    #lives_ok {
        #foreach my $datacenter ( @$registerItems ) {
            #foreach my $datacenterChildren (@{ $datacenter->{children} }) {
                #if ($datacenterChildren->{type} eq 'hypervisor') {
                    #my $vms = $vsphere->retrieveHypervisorVms(
                                  #datacenter_name    =>    $datacenter->{name},
                                  #hypervisor_name    =>    $datacenterChildren->{name},
                              #);
                    #$datacenterChildren->{children} = $vms;
                #}
            #}
        #}
    #} 'retrieve VMs on Hypervisors (hosted on Datacenter)';

    lives_ok {
        foreach my $datacenter ( @$registerItems ) {
            foreach my $datacenterChildren (@{ $datacenter->{children} }) {
                if ($datacenterChildren->{type} eq 'cluster') {
                    my $clusterHypervisors = $vsphere->retrieveClusterHypervisors(
                                                 datacenter_name    =>    $datacenter->{name},
                                                 cluster_name       =>    $datacenterChildren->{name},
                                             );
                    $datacenterChildren->{children} = $clusterHypervisors;
                }
            }
        }
    } 'retrieve Cluster\'s Hypervisors';

    lives_ok {
        foreach my $datacenter ( @$registerItems ) {
            foreach my $datacenterChildren (@{ $datacenter->{children} }) {
                if ($datacenterChildren->{type} eq 'cluster') {
                    foreach my $clusterHypervisor (@{ $datacenterChildren->{children} }) {
                        #Change type 'clusterHypervisor' to 'hypervisor'
                        $clusterHypervisor->{type} = 'hypervisor';
                        my $vms = $vsphere->retrieveHypervisorVms(
                                      datacenter_name    =>    $datacenter->{name},
                                      cluster_name       =>    $datacenterChildren->{name},
                                      hypervisor_name    =>    $clusterHypervisor->{name},
                                  );
                        $clusterHypervisor->{children} = $vms;
                    }
                }
            }
        }
    } 'retrieve VMs on Cluster\'s Hypervisors';

    #lives_ok {
        #$vsphere->register(register_items => $registerItems);
    #} 'register items in Kanopya';

    # TODO: retrieve items from Kanopya and compare them with register_items OR Compare number of registers items returned by register()

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
};    

if($@) {
    my $error = $@; 
    print $error."\n";
}
