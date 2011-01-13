#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);

use Log::Log4perl qw(:easy);
Log::Log4perl->init('/opt/kanopya/conf/log.conf');

use Test::More tests => 18;
use Test::Exception;

BEGIN { 
	use_ok('Administrator'); 
	use_ok('Entity::User');
	use_ok('Entity::Groups');
	use_ok('Entity::Cluster');
}

BEGIN {

print "\n------ authentification tests ------\n\n";

throws_ok { my $admin = Administrator->new(); } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to instanciate Administrator';
throws_ok { my $cluster = Entity::Cluster->get(id => 1) } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to retrieve an entity';
throws_ok { Administrator::authenticate(login => '', password => 'admin'); } "Kanopya::Exception::AuthenticationFailed", "Authentication failed with incorrect login";
throws_ok { Administrator::authenticate(login => 'admin', password => ''); } "Kanopya::Exception::AuthenticationFailed", "Authentication failed with incorrect password";
lives_ok { Administrator::authenticate(login => 'admin', password => 'admin'); }  "Authentication succeed with correct login/password";

Administrator::authenticate(login => 'admin', password => 'admin');
ok(exists $ENV{EID}, 'after authentication, environment variable EID exists');
ok(defined $ENV{EID}, 'after authentication, environment variable EID defined');
my $user_admin_eid = $ENV{EID};
my $adm = Administrator->new();

isa_ok($adm->{_rightchecker}, 'EntityRights::System',	'for user admin, $adm->{_rightschecker}');
is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::System match $ENV{EID}');

Administrator::authenticate(login => 'guest', password => 'guest');
my $user_guest_eid = $ENV{EID};
$adm = Administrator->new();
isnt($ENV{EID}, $user_admin_eid, "environment variable EID changed during reauthentication");
isa_ok($adm->{_rightchecker}, 'EntityRights::User',	'for user guest, $adm->{_rightschecker}');
is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::User match $ENV{EID}');

print "\n------ Permission checking tests ------\n\n";

isnt($adm->{_rightchecker}->checkPerm(entity_id => 61, method => 'get'), 1, 'guest user cant retrieve entity main cluster');
my $cluster;
throws_ok { $cluster = Entity::Cluster->get(id => 1); } "Kanopya::Exception", 'Kanopya::Exception::Permission::Denied thrown';

Administrator::authenticate(login => 'admin', password => 'admin');
$adm = Administrator->new();
is($adm->{_rightchecker}->checkPerm(entity_id => 61, method => 'get'), 1, 'admin user can retrieve entity main cluster');
lives_ok { $cluster = Entity::Cluster->get(id => 1) } 'No exception thrown';

# tester que guest ne peut pas créer de cluster 
# tester que admin peut créer un cluster
# ajouter le droit à guest de créer un cluster
# tester que guest peut créer un cluster






}