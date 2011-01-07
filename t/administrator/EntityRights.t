#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);

use Log::Log4perl qw(:easy);
Log::Log4perl->init('/opt/kanopya/conf/log.conf');

use Test::More tests => 16;

BEGIN { 
	use_ok('Administrator'); 
	use_ok('Entity::User');
	use_ok('Entity::Groups');
}

BEGIN {

print "\n------ system'user ('admin') tests ------\n\n";

Administrator::authenticate(login => 'admin', password => 'admin');

my $guest_user = Entity::User->get(id => 3);

ok(exists $ENV{EID}, 'environment variable EID exists');
ok(defined $ENV{EID}, 'environment variable EID defined');

my $env_eid = $ENV{EID};

my $adm = new_ok('Administrator' => [], '$adm');

isa_ok($adm->{db}, 'AdministratorDB::Schema',	'$admin->{db}');

isa_ok($adm->{_rightchecker}, 'EntityRights::System',	'for user admin, $adm->{_rightschecker}');

is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::System match $ENV{EID}');

can_ok('EntityRights::System', qw(_getEntityIds checkMethodPerm addMethodPerm));

ok($adm->{_rightchecker}->checkMethodPerm(), 'EntityRights::System->checkMethodPerm method always return 1');

#my $entityIds = $adm->{_rightchecker}->_getEntityIds(entity_id => $ENV{EID});
#foreach my $id (@$entityIds) { print "\t$id\n"; }


print "\n------ basic'user ('guest') tests ------\n\n";

Administrator::authenticate(login => 'guest', password => 'guest');

$adm = new_ok('Administrator' => [], '$adm');

ok(exists $ENV{EID}, 'environment variable EID exists');
ok(defined $ENV{EID}, 'environment variable EID defined');

isnt($ENV{EID}, $env_eid, "environment variable EID changed during reauthentification");
isa_ok($adm->{_rightchecker}, 'EntityRights::User',	'for user guest, $adm->{_rightschecker}');


$adm->{_rightchecker}->addMethodPerm(consumer_id => $ENV{EID}, consumed_id => 60, method => 'todo');



}