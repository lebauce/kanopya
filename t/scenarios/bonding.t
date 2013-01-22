#!/usr/bin/perl -w

=head1 SCOPE

Setup a cluster with a bonded interface, and provide it an host with the matching bonded ifaces
Deactivate one of the slave, ping the bonded iface, then reactivate the iface and deactivate the
other slave, and ping again the master.

=head1 PRE-REQUISITE

=cut

use Test::More 'no_plan';
use Test::Exception;

use Log::Log4perl qw(:easy get_logger);
Log::Log4perl->easy_init({
    level=>'DEBUG',
    file=>'Bonding.t.log',
    layout=>'%F %L %p %m%n'
});

use Administrator;
use Entity::Host;
use Entity::Iface;
use Net::Ping;
use Ip;

use Kanopya::Tools::Execution;
use Kanopya::Tools::Register;
use Kanopya::Tools::Retrieve;
use Kanopya::Tools::Create;

my $testing = 0;

my $NB_HYPERVISORS = 1;

main();

sub main {
    Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
    my $adm = Administrator->new;

    if ($testing == 1) {
        $adm->beginTransaction;
    }

    my $host = Entity::Host->find(hash => { 
	           -or => [ host_serial_number => 'Desperado', host_serial_number => 'Heineken', host_serial_number => 'Swinkels' ] 
	       });
    
    my $eth3 = Entity::Iface->find(hash => {
                   iface_name => 'eth3',
                   host_id    => $host->id,
               });
    $eth3->setAttr(name => 'iface_name', value => 'bond0');
    $eth3->save();

    my $eth1 = Entity::Iface->find(hash => {
	           iface_name => 'eth1',
		   host_id    => $host->id,
	       });

    $eth1->setAttr(name => 'master', value => 'bond0');
    $eth1->save();

     my $eth2 = Entity::Iface->find(hash => {
	           iface_name => 'eth2',
		   host_id    => $host->id,
	       });

    $eth2->setAttr(name => 'master', value => 'bond0');
    $eth2->save();
    
    diag('register masterimage');
    Kanopya::Tools::Register::registerMasterImage();

    diag('retrieve admin netconf');
    my $adminnetconf = Kanopya::Tools::Retrieve->retrieveNetconf(criteria => { netconf_name => 'Kanopya admin' });

    diag('Create and configure cluster');
    my $bondage = Kanopya::Tools::Create->createCluster(
                      cluster_conf => {
                          cluster_name => 'Bondage',
                          cluster_basehostname => 'bondage',
                      },
                      interfaces => {
                          public => {
                              interface_netconfs  => { $adminnetconf->id => $adminnetconf->id },
                              bonds_number => 2
                          },
                      }
                  );

    diag('Start host with bonded interfaces');
    Kanopya::Tools::Execution->startCluster(cluster => $bondage);

    diag('deactivate slave n°1');
    _deactivate_iface(iface => 'eth1', cluster => $bondage);

    diag('ping iface bond0');
    _ping_ifaces();

    diag('deactivate slave n°2');
    _deactivate_iface(iface => 'eth2', cluster => $bondage);

    diag('ping iface bond0');
    _ping_ifaces();

    if($testing == 1) {
        $adm->rollbackTransaction;
    }
}

sub _deactivate_iface {
    my %args = @_;

    General::checkParams(args => \%args, required => ['iface','cluster']);

    my @hosts = values (%{ $args{cluster}->getHosts() });
    my $host = pop @hosts;
    my $ehost = EEntity->new(entity => $host);
    $ehost->getEContext->execute(command => 'ifconfig ' . $args{iface} . ' down');
}


sub _ping_ifaces {
    lives_ok {
        diag('retrieve Cluster via name');
        my $cluster = Kanopya::Tools::Retrieve->retrieveCluster(criteria => {cluster_name => 'Bondage'});

        my $hosts = $cluster->getHosts();
        my @bonded_ifaces;
        foreach my $host (values %$hosts) {
            my @ifaces = grep { scalar @{ $_->slaves} > 0 } Entity::Iface->find(hash => {host_id => $host->id});
            push @bonded_ifaces, @ifaces;
        }

        my $ip;
        my $ping;
        my $pingable = 0;
        foreach my $iface (@bonded_ifaces) {
            $ping = Net::Ping->new('icmp');
            $pingable |= $ping->ping($iface->getIPAddr, 10);
        }
    } 'ping cluster\'s hosts bonded ifaces';
}

1;
