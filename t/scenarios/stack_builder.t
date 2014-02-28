#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;

use Entity::ServiceProvider::Cluster;
use Entity::Network;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'stack_builder.t.log',
    layout => '%F %L %p %m%n'
});


my $testing = 0;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    my $builder;
    lives_ok {
       $builder = Entity::ServiceProvider::Cluster->getKanopyaCluster->getComponent(
                      name => "KanopyaStackBuilder"
                  );
    } 'Get the StackBuilder component';

    my $stack = {
        services => [
            # Service "PMS Distributed Controller"
            {
                cpu        => 2,
                ram        => 1073741824,
                components => [
                    {
                        component_type => 'Keystone',
                        conf => {}
                    },
                    {
                        component_type => 'Neutron',
                        conf => {}
                    },
                    {
                        component_type => 'Glance',
                        conf => {}
                    },
                    {
                        component_type => 'Apache',
                        conf => {}
                    },
                    {
                        component_type => 'NovaController',
                        conf => {}
                    },
                    {
                        component_type => 'Cinder',
                        conf => {}
                    },
                    {
                        component_type => 'Lvm',
                        conf => {}
                    },
                ],
            },
            # Service "PMS Compute"
            {
                cpu        => 2,
                ram        => 1073741824,
                components => [
                    {
                        component_type => 'NovaCompute',
                        conf => {}
                    },
                ],
            },
            # Service "PMS DB and Messaging"
            {
                cpu        => 2,
                ram        => 1073741824,
                components => [
                    {
                        component_type => 'Amqp',
                        conf => {}
                    },
                    {
                        component_type => 'Mysql',
                        conf => {}
                    },
                ],
            },
        ],
        iprange  => Entity::Network->find()->network_addr . "/24"
    };

    my $build_stack;
    lives_ok {
       $build_stack = $builder->buildStack(stack => $stack);
    } 'Run workflow BuildStack';

    Kanopya::Tools::Execution->executeOne(entity => $build_stack);

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
