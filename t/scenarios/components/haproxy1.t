#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';

BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::ServiceProvider::Inside::Cluster' );
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
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => 1);

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
    
    my $mount_point = "/tmp";

    my %generated_files = (
	'haproxy' => ['haproxy.cfg'],
	'default' => ['haproxy'],
    );

    for my $dest_dir (keys %generated_files) {
        `mkdir -p $mount_point/$dest_dir`;
    }
    
    $ecomp->configureNode( econtext => $econtext, mount_point => $mount_point,
			   template_path => "/opt/kanopya/templates/components/haproxy",
			   motherboard => "",
			   cluster => $cluster);
    
    while ( my ($dest_dir, $files) =  each %generated_files ) {
        for my $file (@$files) {
	    ok( -f "$mount_point/$dest_dir/$file", "File generated: $file" );
	}
    }

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
