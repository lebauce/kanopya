#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);
use Log::Log4perl qw(:easy);
Log::Log4perl->init('/opt/kanopya/conf/executor-log.conf');

use Test::More;
use Test::Exception;


BEGIN { 

    plan tests => 28;
    #plan skip_all => "Not up to date!";

    use_ok('Administrator'); 
    use_ok('Entity::User');
    use_ok('Entity::Gp');
    use_ok('Entity::Host');
    use_ok('Entity::Systemimage');
    use_ok('Entity::ServiceProvider::Inside::Cluster');
}

diag('authentification tests');

throws_ok { my $admin = Administrator->new(); } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to instanciate Administrator';
throws_ok { my $user = Entity::User->get(id => 1) } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to retrieve an Entity::User';
throws_ok { my $groups = Entity::Gp->get(id => 1) } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to retrieve an Entity::Groups';
throws_ok { my $host = Entity::Host->get(id => 1) } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to retrieve an Entity::Host';
throws_ok { my $systemimage = Entity::Systemimage->get(id => 1) } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to retrieve an Entity::Systemimage';
throws_ok { my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => 1) } "Kanopya::Exception::AuthenticationRequired", 'Authentication required to retrieve an Entity::ServiceProvider::Inside::Cluster';

throws_ok { Administrator::authenticate(login => '', password => ''); } "Kanopya::Exception::AuthenticationFailed", "Authentication failed with incorrect login/password";
throws_ok { Administrator::authenticate(login => '', password => 'admin'); } "Kanopya::Exception::AuthenticationFailed", "Authentication failed with incorrect login";
throws_ok { Administrator::authenticate(login => 'admin', password => ''); } "Kanopya::Exception::AuthenticationFailed", "Authentication failed with incorrect password";
lives_ok { Administrator::authenticate(login => 'admin', password => 'K4n0pY4'); }  "Authentication succeed with correct login/password for admin user";
lives_ok { Administrator::authenticate(login => 'executor', password => 'K4n0pY4'); }  "Authentication succeed with correct login/password for executor user";
lives_ok { Administrator::authenticate(login => 'guest', password => 'guest'); }  "Authentication succeed with correct login/password for guest user";

Administrator::authenticate(login => 'admin', password => 'k4n0pY4');
ok(exists $ENV{EID}, 'after authentication, environment variable EID exists');
ok(defined $ENV{EID}, 'after authentication, environment variable EID defined');

my $user_admin_eid = $ENV{EID};
my $adm = Administrator->new();
isa_ok($adm->{_rightchecker}, 'EntityRights::System',	'for user admin, $adm->{_rightschecker}');
is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::System match $ENV{EID}');

Administrator::authenticate(login => 'executor', password => 'K4n0pY4');
my $user_executor_eid = $ENV{EID};
$adm = Administrator->new();
isnt($ENV{EID}, $user_admin_eid, "environment variable EID changed during reauthentication");
isa_ok($adm->{_rightchecker}, 'EntityRights::System',	'for user executer, $adm->{_rightschecker}');
is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::System match $ENV{EID}');

Administrator::authenticate(login => 'guest', password => 'guest');
my $user_guest_eid = $ENV{EID};
$adm = Administrator->new();
isnt($ENV{EID}, $user_executor_eid, "environment variable EID changed during reauthentication");
isa_ok($adm->{_rightchecker}, 'EntityRights::User',	'for user guest, $adm->{_rightschecker}');
is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::User match $ENV{EID}');
