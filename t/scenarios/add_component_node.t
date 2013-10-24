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

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'add_component_node.t.log',
    layout=>'%F %L %p %m%n'
});

use Kanopya::Database;
use ClassType::ComponentType;
use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Create;

main();

sub main {
    diag('Register master image');
    my $masterimage = Kanopya::Tools::Register::registerMasterImage();

    diag('Creating cluster with Mysql, AMQP and Keystone Components...');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster(
                        cluster_conf => {
                            cluster_name         => 'CloudController',
                            cluster_basehostname => 'cloud',
                            masterimage_id       => $masterimage->id
                        },
                        components => {
                            'mysql' => {
                            },
                            'amqp'  => {
                            },
                        }
                   );
    } 'Cluster created';

    diag('Get components');
    my $sql = $cluster->getComponent(name => 'Mysql');
    my $amqp = $cluster->getComponent(name => 'Amqp');

    diag('Starting cluster...');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Cluster started';

    my ($mysql_node, $rabbitmq_node);
    
    diag('Adding another node with Mysql component only...');
    lives_ok {
        $mysql_node = Kanopya::Tools::Execution->addNode(
                      cluster => $cluster, 
                      component_types => [$sql->component_type_id]);
    } 'mysql_node with started';

    diag('Adding another node with rabbitmq component only...');
    lives_ok {
        $rabbitmq_node = Kanopya::Tools::Execution->addNode(
                         cluster => $cluster, 
                         component_types => [$amqp->component_type_id]);
    } 'rabbitmq_node started';
    
    diag("Adding mysql component to rabbitmq_node...");
    lives_ok {
        $cluster->addComponents(
            nodes => [$rabbitmq_node->id],
            component_types => [ $sql->component_type_id ],
        );
    } 'Component Mysql added to rabbitmq_node';

    diag("Adding Rabbitmq component to mysql_node...");
    lives_ok {
        $cluster->addComponents(
            nodes => [$mysql_node->id],
            component_types => [$amqp->component_type_id ],
        );
    } 'Component Rabbitmq added to mysql_node';
}

1;
