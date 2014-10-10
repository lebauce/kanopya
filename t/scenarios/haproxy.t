#!/usr/bin/perl -w

=head1 SCOPE

TODO

=head1 PRE-REQUISITE

TODO

=cut

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'haproxy.t.log',
    layout=>'%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;
use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;
use Kanopya::Test::TestUtils 'expectedException';


main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Test::Execution::registerMasterImage('ubuntu-precise-amd64.tar.bz2');
    } 'Register master image';

    diag('Create LoadBalancerService cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Test::Create->createCluster(
                        cluster_conf => {
                            cluster_name         => 'LoadBalancerService',
                            cluster_basehostname => 'lbnode',
                            masterimage_id       => $masterimage->id
                        },
                        components => {
                            'mysql' => {},
                            'haproxy' => {},
                        }
                    );
    } 'Create LoadBalancerService cluster';

    my $mysql = $cluster->getComponent(name => 'Mysql');
    my $haproxy = $cluster->getComponent(name => 'Haproxy');

    diag('Configure haproxy');
    
    lives_ok {
        $haproxy->setConf(conf => {
            haproxy1_listens => [ { listen_name    => 'mysql',
                                    listen_ip      => '0.0.0.0',
                                    listen_port    => 33060,
                                    listen_mode    => 'tcp',
                                    listen_balance => 'roundrobin',
                                    listen_component_id   => $mysql->id,
                                    listen_component_port => 3306
                                  }
                                ]
        });
    } 'Configure haproxy';

    
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start LoadBalancerService cluster';

    diag("Add a second node");
    $cluster->addNode();
    lives_ok {
        Kanopya::Test::Execution->executeAll(timeout => 3600);
    }

}
