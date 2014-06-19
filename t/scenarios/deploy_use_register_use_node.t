#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use File::Basename;
use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => basename(__FILE__) . '.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;

use Entity::Systemimage;
use Entity::Node;
use Entity::Component::KanopyaExecutor;
use Entity::Component::Lvm2;
use Entity::Component::Iscsi::Iscsitarget1;
use Entity::Component::Linux::Debian;
use Entity::Component::Openssh5;
use Entity::Component::DummyHostManager;
use EEntity;

my $host_name = "deploy_node_test_" . time();

my $testing = 0;

main();

sub main {
    diag('Get any executor');
    my $executor;
    lives_ok {
        $executor = Entity::Component::KanopyaExecutor->find();
    } 'Get any executor';

    diag('Geta free host');
    my $host;
    if ($testing) {
        $host = EEntity->new(entity => Entity::Component::DummyHostManager->find())->getFreeHost(
                    ram => 8 * 12014 *1024 *1024,
                    cpu => 4
                );
    }
    else {
        $host = Entity::Host->find(hash => { host_state =>  { 'LIKE' =>  'down:%' } });
    }

    diag('Create the node and register components');
    my $lvm = Entity::Component::Lvm2->new(executor_component => $executor);
    my $register_params = {
        host        => $host,
        hostname    => $host_name,
        nameserver1 => '208.67.222.222',
        nameserver2 => '127.0.0.1',
        domainname  => 'my.domain',
        netconf     => Entity::Netconf->find(hash => { netconf_name => "Kanopya admin" }),
        components  => [ $lvm ]
    };

    # Keep the database state before the deploymemnt
    my $dumpfile = Kanopya::Database::dumpDatabase();

    my $node;
    lives_ok {
        $node = Kanopya::Test::Register->registerNode(%{ $register_params });
    } 'Create the node and register components';

    diag('Deploy the node');
    lives_ok {
        Kanopya::Test::Execution->deployNode(node => $node);

    } 'Deploy the node';

    diag('Check for node up');
    lives_ok {
        Kanopya::Test::Execution->checkNodeUp(node => $node);

    } 'Check for node up';


    # Keep the ip assigned during deployment
    my $ip_addr = $node->adminIp;

    # diag('Use a component on the deployed node (Lvm2->createDisk)');
    # lives_ok {
    #     $lvm->createDisk(name       => 'lv_on_deployed_lvm2' . time, 
    #                      size       => 1024 * 2014
    #                      filesystem => "ext3")
    # } 'Deploy the node via the KanopyaDeploymentManager';


    # Rollback the transaction to make HCM ignoring all the deployment sequence
    # Now we have a running node unknown by HCM
    diag('Restore the database to make HCM ignoring all the deployment sequence');
    Kanopya::Database::restoreDatabase(filepath => $dumpfile);

    lives_ok {
        $node = Kanopya::Test::Register->registerNode(existing => 1,
                                                       ip_addr  => $ip_addr,
                                                       %{ $register_params });
    } 'Register the existing node or the existing running host';

    diag('Check for node up');
    lives_ok {
        Kanopya::Test::Execution->checkNodeUp(node => $node);

    } 'Check for node up';
}

1;
