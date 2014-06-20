#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ClassType::ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/StartSLESIaaS.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;
use Entity::ServiceProvider::Cluster;
use Entity::User;
use Entity::Host;
use Entity::Kernel;
use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Masterimage;
use Entity::Network;
use Entity::Poolip;
use Entity::Netconf;
use Entity::NetconfRole;
use NetconfPoolip;
use Entity::Operation;
use Entity::ServiceTemplate;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;

my $testing = 0;

eval {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register master image');
    my $sles_on = Kanopya::Test::Execution::registerMasterImage();

    diag('Setting the default gateway');
    my $kanopya = Kanopya::Test::Retrieve::retrieveCluster();
    my $network = Entity::Network->find(hash => { network_name => "admin" });
    $network->setAttr(name  => "network_gateway",
                      value => $kanopya->getMasterNode->adminIp);
    $network->save();

    diag ('create iaas cluster');
    my $iaas = Kanopya::Test::Create->createIaasCluster(
                   iaas_type    => 'opennebula',
                   cluster_conf => {
                       cluster_name         => 'OpenNebula',
                       cluster_basehostname => 'opennebula',
                       masterimage_id       => $sles_on->id,
                       default_gateway_id   => $network->id
                   }
               );

    diag('Start hypervisor');
    lives_ok {
        # Kanopya::Test::Execution->startCluster(cluster => $iaas);
    } 'Start opennebula iaas cluster';

    diag('Register master image');
    my $sles = Kanopya::Test::Execution::registerMasterImage("sles-11-simple-host.tar.bz2");

    diag ('create vm cluster');
    my $vm_cluster = Kanopya::Test::Create->createVmCluster(
                         iaas => $iaas,
                         cluster_conf => {
                             cluster_name => 'VmCluster',
                             cluster_basehostname => 'vmcluster',
                             masterimage_id => $sles->id,
                         }
                     );

    $vm_cluster->setAttr(name  => 'service_template_id',
                         value => Entity::ServiceTemplate->find(hash => {})->id);
    $vm_cluster->save();

    diag('Start vm');
    lives_ok {
        # Kanopya::Test::Execution->startCluster(cluster => $vm_cluster);
    } 'Start vm cluster';


};
if($@) {
    my $error = $@;
    print $error."\n";
};

