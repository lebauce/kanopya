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

print "\n------ system'user ('admin') tests ------\n\n";

Administrator::authenticate(login => 'admin', password => 'admin');

ok(exists $ENV{EID}, 'environment variable EID exists');
ok(defined $ENV{EID}, 'environment variable EID defined');

my $env_eid = $ENV{EID};

my $adm = new_ok('Administrator' => [], '$adm');

isa_ok($adm->{db}, 'AdministratorDB::Schema',	'$admin->{db}');

isa_ok($adm->{_rightchecker}, 'EntityRights::System',	'for user admin, $adm->{_rightschecker}');

is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::System match $ENV{EID}');

can_ok('EntityRights::System', qw(_getEntityIds checkPerm addPerm));

ok($adm->{_rightchecker}->checkPerm(), 'EntityRights::System->checkPerm method always return 1');


print "\n------ basic'user ('guest') tests ------\n\n";


Administrator::authenticate(login => 'guest', password => 'guest');

$adm = new_ok('Administrator' => [], '$adm');

ok(exists $ENV{EID}, 'environment variable EID exists');
ok(defined $ENV{EID}, 'environment variable EID defined');

isnt($ENV{EID}, $env_eid, "environment variable EID changed during reauthentification");
isa_ok($adm->{_rightchecker}, 'EntityRights::User',	'for user guest, $adm->{_rightschecker}');

isnt($adm->{_rightchecker}->checkPerm(entity_id => 61, method => 'get'), 1, 'guest user cant retrieve main cluster');

eval { my $cluster = Entity::Cluster->get(id => 1); };
if($@) { print $@; } 

#throw_ok { Entity::Cluster->get(id => 1); } "Kanopya::Exception", 'permission denied';



}