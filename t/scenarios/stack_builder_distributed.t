#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;

use Entity::ServiceProvider::Cluster;
use Entity::Network;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'stack_builder_distributed.t.log',
    layout => '%d [ %H - %P ] %p -> %M - %m%n'
});


my $testing = 0;

main();

sub main {

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    lives_ok {
        $masterimage = Kanopya::Test::Execution::registerMasterImage();
    } 'Register master image';

    my $builder;
    lives_ok {
       $builder = Entity::ServiceProvider::Cluster->getKanopyaCluster->getComponent(
                      name => "KanopyaStackBuilder"
                  );
    } 'Get the StackBuilder component';

    my $stack = {
        stack_id => 123,
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
                        conf => {
                            extra => {
                                network => '172.18.42.0/24'
                            }
                        }
                    },
                    {
                        component_type => 'Glance',
                        conf => {
                            extra => {
                                images => {
                                    'ubuntu-12.04' => 'precise-server-cloudimg-amd64-disk1.img',
                                    'fedora-20'    => 'Fedora-x86_64-20-20131211.1-sda.qcow2'
                                }
                            }
                        }
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
                cluster_min_node => 2,
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
       Kanopya::Test::Execution->executeOne(entity => $build_stack);
    } 'Run workflow BuildStack';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
