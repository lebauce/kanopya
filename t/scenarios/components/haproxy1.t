#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';

BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::Cluster' );
      use_ok( 'Entity::Component::HAProxy1' );
      use_ok( 'EEntity::EComponent::EHAProxy1' );
      use_ok( 'EContext::Local' );
}

Administrator::authenticate(login => "admin", password => "K4n0pY4");

my $adm = Administrator->new();

eval {
    $adm->{db}->txn_begin;
    
    # Register component
    my $comp_id = $adm->registerComponent( component_name => 'HAProxy', component_category => 'Proxy', component_version => 1 );

    # Get admin cluster
    my $cluster = Entity::Cluster->get(id => 1);

    # Create a component instance for this cluster
    my $comp_inst_id = $cluster->addComponent( component_id => $comp_id );
    
    # Retrieve component
    #my $comp = $cluster->getComponent( category => 'Logger', name => 'Syslogng', version => 3 );
    my $comp = Entity::Component::HAProxy1->get( id => $comp_inst_id );
    isa_ok($comp, "Entity::Component::HAProxy1", "Retrieve concrete component");
	
    my $new_conf = {

    };
    
#    $comp->setConf( $new_conf );
    
    #my $data = $comp->getConf();
    
    
    my $econtext = EContext::Local->new();
    my $ecomp = EEntity::EComponent::EHAProxy1->new( data => $comp );
    
    for my $dest_dir ("/tmp/haproxy", "/tmp/default") {
        `mkdir $dest_dir` if not -d $dest_dir;
    }
    
    $ecomp->configureNode( econtext => $econtext, mount_point => "/tmp", template_path => "/opt/kanopya/templates/components/haproxy", motherboard => "" );
    
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
