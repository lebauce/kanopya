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
    file=>'vlan.t.log',
    layout=>'%d [ %H - %P ] %p -> %M - %m%n'
});

use Kanopya::Database;
use NetconfVlan;
use Entity::Vlan;

use Kanopya::Test::Execution;
use Kanopya::Test::Register;
use Kanopya::Test::Retrieve;
use Kanopya::Test::Create;
use Kanopya::Test::TestUtils 'expectedException';

my $testing = 0;

main();

sub main {
    Kanopya::Database::authenticate( login =>'admin', password => 'K4n0pY4' );

    if ($testing == 1) {
        Kanopya::Database::beginTransaction;
    }

    diag('Register master image');
    my $masterimage;
    lives_ok {
        $masterimage = Kanopya::Test::Execution::registerMasterImage();
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Test::Create->createCluster(
            cluster_conf => {
                masterimage_id       => $masterimage->id,
            },
        );
    } 'Create cluster';

    diag('add two vlans to admin netconf');
    my $adminnetconf = Kanopya::Test::Retrieve->retrieveNetconf(criteria => { netconf_name => 'Kanopya admin' });
    my $vlan1 = Entity::Vlan->new(vlan_name => 'prodvlan1', vlan_number => '20');
    my $vlan2 = Entity::Vlan->new(vlan_name => 'prodvlan2', vlan_number => '50');
    NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan1->id);
    NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan2->id);

    diag('Start physical host');
    lives_ok {
        Kanopya::Test::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    if ($testing == 1) {
        Kanopya::Database::rollbackTransaction;
    }
}
