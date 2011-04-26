#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';

BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::Cluster' );
      use_ok( 'Entity::Component::Library::Php5' );
}

Administrator::authenticate(login => "admin", password => "admin");

my $adm = Administrator->new();

eval {
    $adm->{db}->txn_begin;
    
	

	my $comp = Entity::Component::Library::Php5->new( );
	
#	$comp->setConf( $new_conf );
	
	#my $data = $comp->getConf();
	
	use EEntity::EComponent::ELibrary::EPhp5;
	use EContext::Local;
	my $econtext = EContext::Local->new();
	my $ecomp = EEntity::EComponent::ELibrary::EPhp5->new( data => $comp );
	
	$dest_dir = "/tmp/components";
	`mkdir $dest_dir` if not -d $dest_dir;
	
	$ecomp->configureNode( econtext => $econtext, mount_point => "/tmp", template_path => ".", motherboard => "" );
	
	#use File::Compare;
	#my $file_compare = File::Compare::compare_text("/tmp/syslog-ng/syslog-ng.conf", "syslog-ng.conf.good");
	#is( $file_compare, 0, "Good generated file");

    $adm->{db}->txn_rollback;
};
if($@) {
    my $error = $@;
       
    $adm->{db}->txn_rollback;
    print "$error";
    exit 233;
}
