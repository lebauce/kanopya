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
use Entity::User::Customer::StackBuilderCustomer;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level  => 'INFO',
    file   => 'stack_builder_allinone.t.log',
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

    my $customer;
    lives_ok {
        $customer = Entity::User::Customer::StackBuilderCustomer->findOrCreate(
            user_login     => 'stack_builder_test',
            user_password  => 'stack_builder_test',
            user_firstname => 'Stack Buil',
            user_lastname  => 'Er test',
            user_email     => 'kpouget@hederatech.com',
        );
    } 'Create a customer stack_builder_test for the owner of the stack';

    my $stack = {
        stack_id => 123,
        services => [
            # Service "PMS Full Controller"
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
                                images => {}
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
            # Service "PMS Compute"
            {
                cpu             => 2,
                ram             => 1073741824,
                cluster_min_node => 2,
                components => [
                    {
                        component_type => 'NovaCompute',
                        conf => {}
                    },
                ],
            },
        ],
        iprange  => Entity::Network->find()->network_addr . "/24"
    };

    my $build_stack;
    lives_ok {
       $build_stack = $builder->buildStack(stack => $stack, owner_id => $customer->id);
       Kanopya::Tools::Execution->executeOne(entity => $build_stack);
    } 'Run workflow BuildStack';

    lives_ok {
        # Find clusters, and associed files
        my $controller = Entity::ServiceProvider::Cluster->find(hash => {'service_template.service_name' =>  'PMS AllInOne Controller'});

        my $fqdn = $controller->getNodeHostname(node_number => 1) . '.';
        $fqdn .= $controller->cluster_domainname;

        my $filename = '/var/lib/kanopya/clusters/override/' . $fqdn . '.yaml';

        if (! -e $filename) {
            throw Kanopya::Exception (error => 'Hiera yaml file for cluster ' . $controller->cluster_name .
                                               ', ' . $filename . ', is not found');
        }

        # Get OS API password :
        $novacontroller = Entity::Component->find(hash => {
                                            'component_type.component_name' => 'NovaController',
                                            'service_provider_id' => $controller->id,
                                        });
        if (!defined $novacontroller->api_password) {
            throw Kanopya::Exception (error => 'API password for cluster' . $controller->cluster_name .
                                               ' is not defined !');
        }

        # Test file strings :


        # Test somes values on host


    }

    my $end_stack;
    lives_ok {
       $end_stack = $builder->endStack(stack_id => 123, owner_id => $customer->id);
       Kanopya::Tools::Execution->executeOne(entity => $end_stack);
    } 'Run workflow EndStack';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
