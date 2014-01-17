#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;
use ClassType::ComponentType;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'keeaplived_ha.t.log',
    layout=>'%F %L %p %m%n'
});

use Net::Ping;
use EContext::SSH;

use Kanopya::Database;
use Entity::ServiceProvider::Cluster;
use Entity::User;
use Entity::Kernel;
use Entity::Processormodel;
use Entity::Hostmodel;
use Entity::Masterimage;
use Entity::Network;
use Entity::Netconf;
use Entity::Poolip;
use Entity::Operation;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;

main();

sub get_node_by_number {
    my %args = @_;
    my $cluster = $args{cluster};
    my $number = $args{number};
    for my $node ($cluster->nodes) {
        if($node->node_number eq "$number") {
            return $node;
        }
    }
    return undef;
}

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register master image');
    lives_ok {
        Kanopya::Tools::Register::registerMasterImage('ubuntu-precise-amd64.tar.bz2');
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster(
            cluster_conf => {
                cluster_name         => 'HACluster',
                cluster_basehostname => 'hanode',
                cluster_min_node     => 1,
                cluster_max_node     => 3,
            },
            components => {
                #'keepalived' => {},
                'apache'    => {},
            },
        );
    } 'Create cluster';

    my $apache2 = $cluster->getComponent(name => 'Apache2');
    isa_ok($apache2, Entity::Component::Apache2, 'Get apache2 component');
    
    lives_ok {
        $apache2->setConf(conf => {
            apache2_loglevel     => 'info',
            apache2_serverroot   => '/srv',
            apache2_ports        => '80',
            apache2_virtualhosts => [ { apache2_virtualhost_servername   => 'my.server.com',
                                        apache2_virtualhost_sslenable    => 'no',
                                        apache2_virtualhost_serveradmin  => 'admin@my.server.com',
                                        apache2_virtualhost_documentroot => '/srv',
                                        apache2_virtualhost_log          => '/tmp/apache_access.log',
                                        apache2_virtualhost_errorlog     => '/tmp/apache_error.log',
                                       } ]
        });
    } 'Configure apache2';
    
    #my $adminpool = Entity::Poolip->find(hash => { poolip_name => 'kanopya_admin' });
    #isa_ok($adminpool, Entity::Poolip, 'Get admin poolip');
        
    #my @interfaces = $cluster->interfaces;
    #my $interface = $interfaces[0];
    #isa_ok($interface, Entity::Interface, 'Get one interfaces');
    #
    #my $vip1 = $adminpool->popIp();
    #isa_ok($vip1, Ip, 'virtual ip 1 created ('.$vip1->ip_addr.')');
    #
    #my $vip2 = $adminpool->popIp();
    #isa_ok($vip2, Ip, 'virtual ip 2 created ('.$vip2->ip_addr.')');
    
    #my $keepalived = $cluster->getComponent(name => 'Keepalived');
    #isa_ok($keepalived, Entity::Component::Keepalived1, 'Get keepalived component');
    
    #lives_ok {
        #$keepalived->setConf(conf => {
            #notification_email => 'toto@toto.fr',
            #smtp_server        => '127.0.0.1',
            #keepalived1_vrrpinstances => [
                #{ vrrpinstance_name      => 'myvirtualip', 
                  #vrrpinstance_password  => 'pass',
                  #interface_id           => $interface->id,
                  #keepalived1_virtualips => [ { ip_id    => $vip1->id,
                                                #interface_id => $interface->id },
                                              #{ ip_id    => $vip2->id,
                                                #interface_id => $interface->id },
                                            #],
                #},
            #]
        #});
    #} 'Configure keepalived';

    # start first keepalived node

    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';
    
    #my $master = get_node_by_number(cluster => $cluster, number => 1);
    #ok($master, "retrieve node 1");
    #
    #my $master_econtext;
    #lives_ok { 
        #$master_econtext = EContext::SSH->new(ip => $master->adminIp, timeout => 10);
    #} 'ssh connection on node 1';
    #
    #my $result = $master_econtext->execute(command => "pgrep keepalived");
    #ok($result->{stdout} ne "", "keepalived process is running on node 1");
    #
    #$result = $master_econtext->execute(command => "grep MASTER /etc/keepalived/keepalived.conf");
    #ok($result->{stdout} ne "", "keepalived configured as MASTER on node 1");
    #
    #diag("test virtual ips reachability");
    #$p = Net::Ping->new('icmp', 10);
    #my $addr1 = $vip1->ip_addr;
    #my $addr2 = $vip2->ip_addr;
    #ok($p->ping($addr1), "vip $addr1 is reachable");
    #ok($p->ping($addr2), "vip $addr2 is reachable");
    
    # start second keepalived node
    
    #diag("start a keepalived backup node");
    #$cluster->addNode();
    #Kanopya::Tools::Execution->executeAll();
    #
    #my $backup = get_node_by_number(cluster => $cluster, number => 2);
    #ok($backup, "retrieve node 2");
    #
    #my $backup_econtext;
    #lives_ok { 
        #$backup_econtext = EContext::SSH->new(ip => $backup->adminIp, timeout => 10);
    #} 'ssh connection on node 2';
    #
    #my $cmd = "pgrep keepalived";
    #$result = $backup_econtext->execute(command => $cmd);
    #ok($result->{stdout} ne "", "keepalived process is running on node 2");
    #
    #$result = $backup_econtext->execute(command => "grep BACKUP /etc/keepalived/keepalived.conf");
    #ok($result->{stdout} ne "", "keepalived configured as BACKUP on node 2");
    #
    #$cmd = "ip addr | grep -E \"inet ($addr1|$addr2)\"";
    #$result = $backup_econtext->execute(command => $cmd);
    #ok($result->{stdout} eq "", "virtual ips not set on node 2");
    
    # shutdown keepalived on master node to simulate problem
    
    #diag("test master to backup virtual ips switching");
    #$cmd = "pkill -9 keepalived";
    #$result = $master_econtext->execute(command => $cmd);
    #ok($result->{exitcode} == 0, "keepalived process shutdown on node 1"); 
    #
    #diag("wait 10 seconds for vrrp");
    #sleep(10);
    #
    #$cmd = "ip addr | grep -E \"inet ($addr1|$addr2)\"";
    #$result = $backup_econtext->execute(command => $cmd);
    #ok($result->{stdout} ne "", "virtual ips set on node 2");
    #
    #ok($p->ping($addr1), "vip $addr1 is reachable");
    #ok($p->ping($addr2), "vip $addr2 is reachable");
    
    # restore keepalived on master node 
    
    #diag("test backup to master virtual ips switching");
    #$cmd = "service keepalived start";
    #$result = $master_econtext->execute(command => $cmd);
    #ok($result->{exitcode} == 0, "keepalived process restarted on node 1"); 
    #
    #diag("wait 10 seconds for vrrp");
    #sleep(10);
    #
    #$cmd = "ip addr | grep -E \"inet ($addr1|$addr2)\"";
    #$result = $backup_econtext->execute(command => $cmd);
    #ok($result->{stdout} eq "", "virtual ips unset on node 2");
    #
    #ok($p->ping($addr1), "vip $addr1 is reachable");
    #ok($p->ping($addr2), "vip $addr2 is reachable");
    
    # start a third non-keepalived node 
    
    #diag("start a third node");
    #$cluster->addNode();
    #Kanopya::Tools::Execution->executeAll();
    #
    #my $othernode = get_node_by_number(cluster => $cluster, number => 3);
    #ok($othernode, "retrieve node 3");
    #
    #my $othernode_econtext;
    #lives_ok { 
        #$othernode_econtext = EContext::SSH->new(ip => $othernode->adminIp, timeout => 10);
    #} 'ssh connection on node 3';
    #
    #$cmd = "pgrep keepalived";
    #$result = $othernode_econtext->execute(command => $cmd);
    #ok($result->{stdout} ne "", "keepalived process not running on node 3");
    
}

1;
