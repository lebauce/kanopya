#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'/vagrant/StartSLESIaaS.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use Executor;
use Entity::ServiceProvider::Inside::Cluster;
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

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;

eval {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    diag('Register master image');
    my $sles_on = Kanopya::Tools::Register::registerMasterImage();

    diag('Setting the default gateway');
    my $kanopya = Kanopya::Tools::Retrieve::retrieveCluster();
    my $network = Entity::Network->find(hash => { network_name => "admin" });
    $network->setAttr(name  => "network_gateway",
                      value => $kanopya->getMasterNode->adminIp);
    $network->save();

    diag ('create iaas cluster');
    my $iaas = Kanopya::Tools::Create->createIaasCluster(
                   cluster_conf => {
                       cluster_name         => 'OpenNebula',
                       cluster_basehostname => 'opennebula',
                       masterimage_id       => $sles_on->id,
                       default_gateway_id   => $network->id
                   }
               );

    diag('Start hypervisor');
    lives_ok {
        # Kanopya::Tools::Execution->startCluster(cluster => $iaas);
    } 'Start opennebula iaas cluster';

    diag('Register master image');
    my $sles = Kanopya::Tools::Register::registerMasterImage("sles-11-simple-host.tar.bz2");

    diag ('create vm cluster');
    my $vm_cluster = Kanopya::Tools::Create->createVmCluster(
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
        # Kanopya::Tools::Execution->startCluster(cluster => $vm_cluster);
    } 'Start vm cluster';


};
if($@) {
    my $error = $@;
    print $error."\n";
};

