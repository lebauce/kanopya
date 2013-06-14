#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'start_vsphere_host.t.log', layout=>'%F %L %p %m%n'});

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

# 1) Create a Iaas Cluster of vSphere type
# 2) Register a vSphere infrastructure
# 3) Create a Vm cluster which use the Iaas host manager
# 4) Start the Vm cluster

my $testing = 0;

my $vsphere_conf = {
    vsphere5_login => 'Administrator',
    vsphere5_pwd   => 'Hedera@123',
    vsphere5_url   => '192.168.2.147',
};

my $v_cluster_name = 'Vsphere';
my $datacenter     = 'HederaCenter';

eval {
    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        BaseDB->beginTransaction;
    }


    lives_ok{
        my $vsphere_cluster = Kanopya::Tools::Create->createIaasCluster(
                                  iaas_type    => 'vsphere',      
                                  vsphere_conf => $vsphere_conf,
                                  cluster_name => 'vSphere',
                              );
    }'Create a Iaas cluster holding vSphere component';

    lives_ok {
        my $vsphere_cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_id => 310});
        my $vsphere = $vsphere_cluster->getComponent(name => 'Vsphere');

        my $dc = $vsphere->registerDatacenter(name => $datacenter);

        my $hypervisors = $vsphere->retrieveClusterHypervisors(
                                          datacenter_name => $datacenter,
                                          cluster_name    => $v_cluster_name,
                                      );

        foreach my $hv (@$hypervisors) {
            $vsphere->registerHypervisor(
                name   => $datacenter,
                uuid   => $hv->{uuid},
                parent => $dc,
            );
        }
    }'Register vSphere infrastructure';

    lives_ok{
        my $vm_cluster = Kanopya::Tools::Create->createVmCluster(
                             iaas => $vsphere_cluster,
                         );
    }'Create VM cluster';

    lives_ok{
        Kanopya::Tools::Execution->startCluster(cluster => $#vm_cluster);
    }'Start VM cluster';

    if ($testing == 1) {
        BaseDB->rollbackTransaction;
    }
};

if($@) {
    my $error = $@;
    print $error."\n";
}
