#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);

use Log::Log4perl qw(:easy);
Log::Log4perl->init('/opt/kanopya/conf/log.conf');

use Test::More tests => 28;
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

print "\n------ 'Guest' user Initial Permissions checking tests ------\n\n";

my $eguest_user;
my $ecluster;

lives_ok { $eguest_user = Entity::User->get(id => 3) } 'Permission granted for guest user to retrieve Entity::User with id 3';
lives_ok { 
	$eguest_user->setAttr(name => 'user_desc', value => 'another description'); 
	$eguest_user->update();
} 'Permission granted for guest user to update entity user with id 3';

throws_ok { $eguest_user->delete() } "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to delete Entity::User with id 3';

throws_ok { $ecluster = Entity::Cluster->get(id => 1) } "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to retrieve Entity::Cluster with id 1';
throws_ok { Entity::Cluster->create() } "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to create an Entity::Cluster';

print "\n------ 'Admin' user Initial Permissions checking tests ------\n\n";

Administrator::authenticate(login => 'admin', password => 'admin');
$adm = Administrator->new();
lives_ok { $ecluster = Entity::Cluster->get(id => 1) } 'Permission granted for admin user to retrieve Entity::Cluster with id 1';
lives_ok { Entity::Cluster->create() } 'Permission granted for admin user to create an Entity::Cluster';

print "\n------ 'Guest' user Permissions setting tests ------\n\n";

lives_ok { 
	$ecluster->addPerm(method => 'get', entity_id => $eguest_user->{_entity_id}) 
} "Permission granted for admin user to add 'get' permission on Entity::Cluster with id 1 for user guest";

lives_ok { 
	Entity::Cluster->addPerm(method => 'create', entity_id => $eguest_user->{_entity_id})
} "Permission granted for admin user to add 'create' permission on Entity::Cluster class for user guest";

Administrator::authenticate(login => 'guest', password => 'guest');
$adm = Administrator->new();
lives_ok { $ecluster = Entity::Cluster->get(id => 1) } 'Permission granted for guest user to retrieve Entity::Cluster with id 1';
lives_ok { Entity::Cluster->create() } 'Permission granted for guest user to create an Entity::Cluster';

throws_ok { 
	$ecluster = Entity::Cluster->get(id => 1);
	$ecluster->addPerm(method => 'delete', entity_id => $eguest_user->{_entity_id}) 
} "Kanopya::Exception::Permission::Denied", "Permission denied for guest user to add 'delete' permission on Entity::Cluster with id 1";




}