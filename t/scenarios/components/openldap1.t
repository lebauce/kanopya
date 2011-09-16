#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';
use EEntity::EComponent::EIptables1;
BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::Cluster' );
      use_ok( 'Entity::Component::Openldap1' );
      use_ok( 'EEntity::EComponent::EOpenldap1' );
      use_ok( 'EContext::Local' );
      use_ok( 'Data::Dumper' );
}

Administrator::authenticate(login => "admin", password => "K4n0pY4");

my $adm = Administrator->new();

eval {
    $adm->{db}->txn_begin;
    
    # Register component
    my $comp_id = $adm->registerComponent( component_name => 'Openldap', component_category => 'Annuary', component_version => 1 );

    # Get admin cluster
    my $cluster = Entity::Cluster->get(id => 2);

    # Create a component instance for this cluster
    my $comp_inst_id = $cluster->addComponent(component_id => $comp_id );
    
    #my $comp_inst_id = 18;
    # Retrieve component
    #my $comp = $cluster->getComponent( category => 'Logger', name => 'Syslogng', version => 3 );   
    my $comp = Entity::Component::Openldap1->get( id => $comp_inst_id );
    
    isa_ok($comp, "Entity::Component::Openldap1", "Retrieve concrete component");
    
    $comp->setConf();
   
  
    
    my $new_conf = {
        
    };
    
#    $comp->setConf( $new_conf );   
    #my $data = $comp->getConf();
    
    # my $a=$comp->setConf();
    #print Dumper $a;
    my $econtext = EContext::Local->new();
    
    
    #print Dumper $comp;
    my $ecomp = EEntity::EComponent::EOpenldap1->new( data => $comp );
    
    
    for my $dest_dir ("/tmp/ldap") {
        `mkdir $dest_dir` if not -d $dest_dir;
    }
    for my $dest_dir ("/tmp/default") {
        `mkdir $dest_dir` if not -d $dest_dir;
    }
    $ecomp->addNode( econtext => $econtext,
                            mount_point => "/tmp", 
                            template_path => "/opt/kanopya/templates/components", 
                            motherboard => "",
                            cluster=>$cluster );
    
    
    $adm->{db}->txn_rollback;
};
if($@) {
    my $error = $@;   
    $adm->{db}->txn_rollback;
    print "$error";
    exit 233;
}
