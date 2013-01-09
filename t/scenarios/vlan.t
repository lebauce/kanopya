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
    file=>'/vagrant/Vlan.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use NetconfVlan;
use Entity::Vlan;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;
use Kanopya::Tools::TestUtils 'expectedException';

my $testing = 0;

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    diag('Register master image');
    lives_ok {
        Kanopya::Tools::Register::registerMasterImage();
    } 'Register master image';

    diag('Create and configure cluster');
    my $cluster;
    lives_ok {
        $cluster = Kanopya::Tools::Create->createCluster();
    } 'Create cluster';

    diag('add two vlans to admin netconf');
    my $adminnetconf = Kanopya::Tools::Retrieve->retrieveNetconf(criteria => { netconf_name => 'Kanopya admin' });
    my $vlan1 = Entity::Vlan->new(vlan_name => 'prodvlan1', vlan_number => '20');
    my $vlan2 = Entity::Vlan->new(vlan_name => 'prodvlan2', vlan_number => '50');
    NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan1->id);
    NetconfVlan->new(netconf_id => $adminnetconf->id, vlan_id => $vlan2->id);

    diag('Start physical host');
    lives_ok {
        Kanopya::Tools::Execution->startCluster(cluster => $cluster);
    } 'Start cluster';

    if ($testing == 1) {
        $adm->rollbackTransaction;
    }
}
