#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl;
Log::Log4perl->init('/workspace/mcs/Administrator/Conf/log.conf');

use lib qw(/workspace/mcs/Administrator/Lib);
use Administrator;

my %args = (login =>'xebech', password => 'pass');
my $adm = Administrator->new( %args);

eval {
	$adm->{db}->txn_begin;
    # change the function to call to do another operation	
	StartCluster();
	$adm->{db}->txn_commit;
};
if ($@){
    my $error = $@;
    print "\nException catch, its type is : " . ref($error);
    print "\n$error\n";
    
	$adm->{db}->txn_rollback;
}

##### here method to add operations #####

sub ActiveSystemimage {
    print "Active systemimage with id 1 ...";
    $adm->newOp(type => "ActiveSystemimage", priority => '100', params => { systemimage_id => 1 });
    print "done\n";
}

sub DeactiveSystemimage {
    print "Deactive systemimage with id 1 ...";
    $adm->newOp(type => "DeactiveSystemimage", priority => '100', params => { systemimage_id => 1 });
    print "done\n";
}

sub AddMotherboard {
    print "Add Motherboard with mac ab:cd:ef:12:34:56 ...";
    $adm->newOp(type => "AddMotherboard", priority => '100', params => { 
	motherboard_mac_address => 'ab:cd:ef:12:34:56', 
	kernel_id => 1, 
	motherboard_serial_number => "abcdef123456",
	motherboard_model_id => 1,
	processor_model_id => 1 }
	);
    print "done\n";
}

sub AddCluster {
    print "Add Cluster with name ClusterForTesting ...";
    $adm->newOp(type => "AddCluster", priority => '100', params => { 
		cluster_name => 'ClusterForTesting', 
		cluster_desc => 'cluster for testing',
		cluster_min_node=> 1,
		cluster_max_node=> 1,
		cluster_priority=> 500,
		systemimage_id=> 1,
		kernel_id=> 1,
		active=> 0}
	);
    print "done\n";
}

sub StartCluster {
    print 'Start Cluster with id 3 ...';
    $adm->newOp(type => 'StartCluster', priority => '1000', params => {
	cluster_id => 3 }
	);
    print "done\n";
}
