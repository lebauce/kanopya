#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Tools::OpenStack;
use Entity::ServiceProvider::Cluster;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'openstack-sync.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;

my $testing = 0;

my $control_daemon_timeout = 30;
my $controller;
my $erabbitmq;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    Kanopya::Tools::OpenStack->start1OpenStackOn3Clusters();

    # Retrieve the NovaController previously deployed 
    my $cloud = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "CloudController" });
    my $amqp  = Entity::ServiceProvider::Cluster->find(hash => { cluster_name => "Database" });
    $controller = $cloud->getComponent(name => "NovaController");

    # Get the KanopyaOpenstackSync on the Kanopya master
    my $openstacksync = Entity::ServiceProvider::Cluster->getKanopyaCluster()->getComponent(name => "KanopyaOpenstackSync");

    # Firstly verify thet the openstack daemon do not consume messages on the
    # NovaController notification queue.
    # Use the node where is the RabbitMQ.
    my @nodes = $amqp->nodes;
    my $rabbitmq = (pop @nodes)->host;

    # Get the EEntity of the host to execute commands on
    $erabbitmq = EEntity->new(entity => $rabbitmq);
    my $result = $erabbitmq->getEContext->execute(command => "rabbitmqctl list_consumers -p openstack-" . $controller->id . " . | grep notifications.info"); 

    ok("$result->{stdout}" eq "", "Check that OpenstackSync do not consume message on queue <notifications.info> on vhost openstack-" . $controller->id);

    diag('Set the open stack sync to the nova controller');
    $controller->update(kanopya_openstack_sync_id => $openstacksync->id);

    waitForOpenstackSyncStartConsuming();

    # Unset the open stack sync to the nova controller
    diag('Unset the open stack sync from the nova controller');
    $controller->update(kanopya_openstack_sync_id => undef);

    waitForOpenstackSyncStopConsuming();

    diag('Set again the open stack sync to the nova controller');
    $controller->update(kanopya_openstack_sync_id => $openstacksync->id);

    waitForOpenstackSyncStartConsuming();

    diag('Stop NovaController instance');
    lives_ok {
        my ($state, $timestamp) = $cloud->reload->getState();
        if ($state ne 'up') {
            die "Cluster should be up, not $state";
        }
        Kanopya::Tools::Execution->executeOne(entity => $cloud->stop());
        Kanopya::Tools::Execution->executeAll(timeout => 3600);
    } 'Stopping NovaController instance';

    waitForOpenstackSyncStopConsuming();

    diag('Restart NovaController instance');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cloud);
    } 'Restart NovaController instance';

    waitForOpenstackSyncStartConsuming();

    # Unset the open stack sync to the nova controller
    diag('Unset the open stack sync from the nova controller');
    $controller->update(kanopya_openstack_sync_id => undef);

    waitForOpenstackSyncStopConsuming();

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}

sub waitForOpenstackSyncStartConsuming {
    diag('Wait for the openstack sync daemon to receive the control message, and start to consume on the notification queue');
    lives_ok {
        # Wait for the openstack sync daemon to receive the control message, and start to consume on the notification queue 
        my $try = 0;
        while ($try < $control_daemon_timeout) {
            my $result = $erabbitmq->getEContext->execute(command => "rabbitmqctl list_consumers -p openstack-" . $controller->id . " . | grep notifications.info");
            if ("$result->{stdout}" ne "") {
                last;
            }
            sleep (1);
            $try++;
        }
        if ($try >= $control_daemon_timeout) {
           die ("The openstack sync daemon seems not to start consuming messages on queue <notifications.info> on vhost openstack-" . $controller->id);
        }
    } 'Openstack sync start consuming messages on queue <notifications.info> on vhost openstack-' . $controller->id . ' after set kanopya_openstack_sync_id on nova controller';
}

sub waitForOpenstackSyncStopConsuming {
    diag('Wait for the openstack sync daemon to receive the control message, and stop to consume on the notification queue');
    lives_ok {
        # Wait for the openstack sync daemon to receive the control message, and stop to consume on the notification queue 
        my $try = 0;
        while ($try < $control_daemon_timeout) {
            my $result = $erabbitmq->getEContext->execute(command => "rabbitmqctl list_consumers -p openstack-" . $controller->id . " . | grep notifications.info");
            if ("$result->{stdout}" eq "") {
                last;
            }
            sleep (1);
            $try++;
        }
        if ($try >= $control_daemon_timeout) {
           die ("The openstack sync daemon seems not to stop consuming messages on queue <notifications.info> on vhost openstack-" . $controller->id);
        }
    } 'Openstack sync stop consuming messages on queue <notifications.info> on vhost openstack-' . $controller->id . ' after set kanopya_openstack_sync_id on nova controller';
}
