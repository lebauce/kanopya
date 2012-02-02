#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';

BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::ServiceProvider::Inside::Cluster' );
      use_ok( 'Entity::Component::Php5' );
}

Administrator::authenticate(login => "admin", password => "K4n0pY4");

my $adm = Administrator->new();

eval {
    $adm->{db}->txn_begin;
    
	

    # We instanciate a new component
    my $comp = Entity::Component::Php5->new( cluster_id => 1, component_id => 15 );
	
#	$comp->setConf( $new_conf );
	

 $comp->setConf( { php5_session_handler => "YYYYYYYYYYYYYYYY" } );	

    use Data::Dumper;
    my $data = $comp->getConf();
    print Dumper $data;

    use EEntity::EComponent::EPhp5;
    use EContext::Local;
    my $econtext = EContext::Local->new();
    my $ecomp = EEntity::EComponent::EPhp5->new( data => $comp );
	
    my $mount_point = "/tmp";
    $dest_dir = $mount_point . "/php5/apache2/";
    `mkdir -p $dest_dir` if not -d $dest_dir;
	
   

    # Test file generation without conf
    $ecomp->configureNode( econtext => $econtext, mount_point => $mount_point, template_path => "/opt/kanopya/templates/components/php5", motherboard => "" );
	
    # 

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
