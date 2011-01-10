#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);

use Log::Log4perl qw(:easy);
Log::Log4perl->init('/opt/kanopya/conf/log.conf');

use Test::More tests => 17;

BEGIN { 
	use_ok('Administrator'); 
	use_ok('Entity::User');
	use_ok('Entity::Groups');
	use_ok('Entity::Motherboard');
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

can_ok('EntityRights::System', qw(_getEntityIds checkMethodPerm addMethodPerm));

ok($adm->{_rightchecker}->checkMethodPerm(), 'EntityRights::System->checkMethodPerm method always return 1');

my $guest = Entity::User->get(id => 3);
my $motherboard = Entity::Motherboard->get(id => 1);

eval {
	$adm->{_rightchecker}->addMethodPerm(
		consumer_id => $guest->{_dbix}->get_column('entity_id'), 
		consumed_id => $motherboard->{_dbix}->get_column('entity_id'),
		method => 'save'
	);
}; if($@) { print $@; }


#my $entityIds = $adm->{_rightchecker}->_getEntityIds(entity_id => $ENV{EID});
#foreach my $id (@$entityIds) { print "\t$id\n"; }


print "\n------ basic'user ('guest') tests ------\n\n";

Administrator::authenticate(login => 'guest', password => 'guest');

$adm = new_ok('Administrator' => [], '$adm');

ok(exists $ENV{EID}, 'environment variable EID exists');
ok(defined $ENV{EID}, 'environment variable EID defined');

isnt($ENV{EID}, $env_eid, "environment variable EID changed during reauthentification");
isa_ok($adm->{_rightchecker}, 'EntityRights::User',	'for user guest, $adm->{_rightschecker}');

}