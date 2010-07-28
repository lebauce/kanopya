#!/usr/bin/perl -w


use lib qw(../Lib ../../Common/Lib);

use McsExceptions;


use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', file=>'STDOUT', layout=>'%F %L %p %m%n'});

use Test::More 'no_plan';
use Administrator;
use Data::Dumper;

my $adm = Administrator->new( login =>'thom', password => 'pass' );

note( "Test Entity management");

eval {
	$adm->{db}->txn_begin;
	
	#################################################################################################################################
	
	# Obj creation
	my $clust = $adm->newEntity( type => "Cluster", params => { cluster_name => 'myclust', 
															  cluster_desc => 'myclust',
															  cluster_min_node => '1',
															  cluster_max_node => '2',
															  cluster_priority => '2',
															  cluster_public_ip => 'pubip',
															  cluster_public_mask => 'pubmask',
															  cluster_public_network => 'pubnet',
															  cluster_public_gateway => 'pubgw',
															  cluster_active => '1',
															  systemimage_id => '1',} );
	isa_ok( $clust, "Entity::Cluster", '$obj');
	is( $clust->{_dbix}->in_storage , 0, "new obj doesn't add in DB" ); 
	is( $clust->getAttr( name => 'cluster_active' ), '1', "get value of new cluster" );
	
	my $cluster = $adm->getEntity(type => "Cluster", id => 1);
	my $components = $cluster->getComponents(administrator => $adm, category => "all");
	$adm->{db}->txn_rollback;
};
if($@) {
	my $error = $@;
	
	$adm->{db}->txn_rollback;
	
	print Dumper $error;
};

