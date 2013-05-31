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
    layout=>'%F %L %p %m%n'
});

use BaseDB;
use NetconfVlan;
use Entity::Vlan;
use Entity::Component::Lvm2::Lvm2Vg;
use Entity::Component::Lvm2::Lvm2Pv;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;
use Kanopya::Tools::TestUtils 'expectedException';


main();

sub main {
    BaseDB->authenticate( login =>'admin', password => 'K4n0pY4' );

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Tools::Register::registerMasterImage('ubuntu-precise-amd64.tar.bz2');
    } 'Register master image';

    diag('Create LoadBalancerService cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster(
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
            haproxy1s_listen => [ { listen_name     => 'mysql',
                                    listen_ip       => '0.0.0.0',
                                    listen_port     => 33060,
                                    listen_mode     => 'tcp',
                                    listen_balance  => 'roundrobin'
                                  }
                                ]
        });
    } 'Configure haproxy';

    
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start LoadBalancerService cluster';

}
