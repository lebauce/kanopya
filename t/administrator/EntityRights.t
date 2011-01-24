#!/usr/bin/perl -w

use FindBin qw($Bin);
use lib qw(/opt/kanopya/lib/common /opt/kanopya/lib/administrator);

use Data::Dumper;
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

diag("'Guest' user Initial Permissions checking tests");

Administrator::authenticate(login => 'guest', password => 'guest');
my $adm = Administrator->new();

my $eguest_user;
my $ecluster;

lives_ok { $eguest_user = Entity::User->get(id => 3) } 'Permission granted for guest user to retrieve Entity::User with id 3';
lives_ok { 
	$eguest_user->setAttr(name => 'user_desc', value => 'another description'); 
	$eguest_user->update();
} 'Permission granted for guest user to update entity user with id 3';

throws_ok { $eguest_user->delete() } "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to delete Entity::User with id 3';

throws_ok {
	my $euser = Entity::User->new( 
	    	user_login => 'toto', 
	    	user_password => 'toto',
	    	user_firstname => 'toto',
	    	user_lastname => 'toto',
	    	user_email => 'toto@toto.fr',
	    	user_desc => 'toto',
	);
	$euser->create();
} "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to create new Entity::User';


#throws_ok { $ecluster = Entity::Cluster->get(id => 1) } "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to retrieve Entity::Cluster with id 1';
#throws_ok { Entity::Cluster->create() } "Kanopya::Exception::Permission::Denied", 'Permission denied for guest user to create an Entity::Cluster';

#print "\n------ 'Admin' user Initial Permissions checking tests ------\n\n";

#Administrator::authenticate(login => 'admin', password => 'admin');
#$adm = Administrator->new();
#lives_ok { $ecluster = Entity::Cluster->get(id => 1) } 'Permission granted for admin user to retrieve Entity::Cluster with id 1';
#lives_ok { Entity::Cluster->create() } 'Permission granted for admin user to create an Entity::Cluster';

#print "\n------ 'Guest' user Permissions setting tests ------\n\n";

#lives_ok { 
#	$ecluster->addPerm(method => 'get', entity_id => $eguest_user->{_entity_id}) 
#} "Permission granted for admin user to add 'get' permission on Entity::Cluster with id 1 for user guest";

#lives_ok { 
	#Entity::Cluster->addPerm(method => 'create', entity_id => $eguest_user->{_entity_id})
#} "Permission granted for admin user to add 'create' permission on Entity::Cluster class for user guest";

#Administrator::authenticate(login => 'guest', password => 'guest');
#$adm = Administrator->new();
#lives_ok { $ecluster = Entity::Cluster->get(id => 1) } 'Permission granted for guest user to retrieve Entity::Cluster with id 1';
#lives_ok { Entity::Cluster->create() } 'Permission granted for guest user to create an Entity::Cluster';

#throws_ok { 
#	$ecluster = Entity::Cluster->get(id => 1);
#	$ecluster->addPerm(method => 'delete', entity_id => $eguest_user->{_entity_id}) 
#} "Kanopya::Exception::Permission::Denied", "Permission denied for guest user to add 'delete' permission on Entity::Cluster with id 1";

#my $masterclustergroups_eid = $adm->{db}->resultset('Groups')->find({ groups_name => 'Cluster' })->groups_entities->first->get_column('entity_id');
#my %granted_methods = $adm->{_rightchecker}->getPerms(consumer_id => $user_guest_eid, consumed_id => $masterclustergroups_eid); 
#print "\ngranted methods for user guest on Entity::Cluster class : ";
#foreach my $method (keys %granted_methods) {
#	print $method." ";
#}
#print "\n";

#print Dumper(Entity::User->getPerms());
#print Dumper($eguest_user->getPerms());


}