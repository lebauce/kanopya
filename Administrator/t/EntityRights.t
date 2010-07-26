#!/usr/bin/perl -w
# $Bin is full path to this file directory
# we can now call this script from everywhere
# warn: not secure
# TODO: il y a surement mieux à faire pour gérer les path
#use FindBin qw($Bin);
#use lib "$Bin/../Lib";
use lib qw(../Lib); # same as above
use Log::Log4perl qw(:easy);
Log::Log4perl->init('../Conf/log.conf');

use Test::More 'no_plan';
use Administrator;
use Data::Dumper;


eval {
	my $adm = Administrator->new( login => 'thom', password => 'pass' );
	isa_ok($adm->{_rightschecker}, "EntityRights", '$adm->{_rightschecker}');
	isa_ok($adm->{_rightschecker}->{_schema}, "AdministratorDB::Schema", '$adm->{_rightschecker}->{_schema}');
	#$adm->{_rightschecker}->{_schema}->storage->debug(1);
	
	my $AdminGroup = $adm->getEntity(type => 'Groups', id => 44 ); # 'admin' group
	my $UserGroup = $adm->getEntity(type => 'Groups', id => 35); # 'User' group
	my $tata = $adm->getEntity(type => 'User', id => 19); # 'tata' user
	
	# getting rights for tata on UserGroup
	$rights = $adm->{_rightschecker}->getRights(consumer => $tata, consumed => $UserGroup);	
	print "rights for tata on UserGroup: $rights\n";
	
	# adding write permission for tata on UserGroup
	$adm->{_rightschecker}->setRights(consumer => $tata, consumed => $UserGroup, rights => 'w');
	
	# getting rights for tata on UserGroup
	$rights = $adm->{_rightschecker}->getRights(consumer => $tata, consumed => $UserGroup);	
	print "rights for tata on UserGroup: $rights\n";
	
	# removing write permission for tata on UserGroup
	#$adm->{_rightschecker}->setRights(consumer => $tata, consumed => $UserGroup, rights => '');

	# getting rights for tata on UserGroup
	#$rights = $adm->{_rightschecker}->getRights(consumer => $tata, consumed => $UserGroup);	
	#print "rights for tata on UserGroup: $rights\n";
	
};

if($@) {
	print $@;
}