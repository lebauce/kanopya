#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);

use Log::Log4perl qw(:easy);
Log::Log4perl->init('/opt/kanopya/conf/log.conf');

use Test::More tests => 9;

BEGIN { use_ok('Administrator'); }
BEGIN {

Administrator::authenticate(login => 'admin', password => 'admin');

ok(exists $ENV{EID}, 'environment variable EID exists');
ok(defined $ENV{EID}, 'environment variable EID defined');

my $adm = new_ok('Administrator' => [], '$adm');

isa_ok($adm->{db}, 'AdministratorDB::Schema',	'$admin->{db}');

isa_ok($adm->{_rightchecker}, 'EntityRights::System',	'for user admin, $adm->{_rightschecker}');

is($adm->{_rightchecker}->{user_entity_id}, $ENV{EID}, 'user_entity_id in EntityRights::System match $ENV{EID}');

can_ok('EntityRights::System', qw(_getEntityIds checkMethodPerm addMethodPerm));

ok($adm->{_rightchecker}->checkMethodPerm(), 'EntityRights::System->checkMethodPerm method always return 1');

#my $entityIds = $adm->{_rightchecker}->_getEntityIds(entity_id => $ENV{EID});
#foreach my $id (@$entityIds) { print "\t$id\n"; }

}