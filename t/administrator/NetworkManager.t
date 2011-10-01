use lib qw(/opt/kanopya/lib/administrator /opt/kanopya/lib/common );

use Data::Dumper;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;



Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
my $adm = Administrator->new();

my $net_manager = $adm->{manager}->{network};


eval {
     $adm->{db}->txn_begin;

     my $dmz_ip = $net_manager->getFreeDmzIP();
     my $dmz_ip_id = $net_manager->newDmzIP(ipv4_address => "$dmz_ip", ipv4_mask =>"255.255.255.0");
     is ($net_manager->getDmzIPId('ipv4_dmz_address' => $dmz_ip), $dmz_ip_id, 'Test if dmz ip creation is ok');
     $net_manager->delDmzIP('ipv4_id' => $dmz_ip_id);
     throws_ok {$net_manager->getDmzIPId('ipv4_dmz_address' => $dmz_ip) } 'Kanopya::Exception::DB',
     "get deleted dmz ip";

     my $internal_ip = $net_manager->getFreeInternalIP();
     my $internal_ip_id = $net_manager->newInternalIP(ipv4_address => "$internal_ip", ipv4_mask =>"255.255.255.0");
     is ($net_manager->getInternalIPId('ipv4_internal_address' => $internal_ip), $internal_ip_id, 'Test if internal ip creation is ok');
     $net_manager->delInternalIP('ipv4_id' => $internal_ip_id);
     throws_ok {$net_manager->getInternalIPId('ipv4_internal_address' => $internal_ip) } 'Kanopya::Exception::DB',
     "get deleted internal ip";

     $adm->{db}->txn_commit;
};
if($@) {
       my $error = $@;
       print "$error";
       $adm->{db}->txn_rollback;
       
       exit 233;
}

