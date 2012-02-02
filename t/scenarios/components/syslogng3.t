#!/usr/bin/perl -w

use lib </opt/kanopya/lib/*>;

use Test::More 'no_plan';

BEGIN {
      use_ok( 'Administrator' );
      use_ok( 'Entity::ServiceProvider::Inside::Cluster' );
      use_ok( 'Entity::Component::Syslogng3' );
      use_ok( 'EEntity::EComponent::ESyslogng3' );
      use_ok( 'EContext::Local' );
}

Administrator::authenticate(login => "admin", password => "K4n0pY4");

my $adm = Administrator->new();

eval {
    $adm->{db}->txn_begin;
    
    # Register component
    my $comp_id = $adm->registerComponent( component_name => 'Syslogng', component_category => 'Logger', component_version => 3 );

    # Get admin cluster
    my $cluster = Entity::ServiceProvider::Inside::Cluster->get(id => 1);

    # Create a component instance for this cluster
    my $comp_inst_id = $cluster->addComponent( component_id => $comp_id );
    
    # Retrieve component
    #my $comp = $cluster->getComponent( category => 'Logger', name => 'Syslogng', version => 3 );
    my $comp = Entity::Component::Syslogng3->get( id => $comp_inst_id );
    isa_ok($comp, "Entity::Component::Syslogng3", "Retrieve concrete component");
	
    my $new_conf = {
	entries => [
	    { entry_type => 'source', entry_name => 'src_one', params => [{ content => "driver1(param1)" }, { content => "driver2(parm1 param2)"}] },
	    { entry_type => 'source', entry_name => 'src_two', params => [{ content => "driver1(param1)" }] },
	    { entry_type => 'destination', entry_name => 'dest_one', params => [{ content => "driver1(param1)" }, { content => "driver2(parm1 param2)"}] },
	    ],
	    logs => [
		{ log_params => [ {type =>'source', name => 'src_two'}, {type =>'destination', name => 'dest_one'}] },
		{ log_params => [ {type =>'source', name => 'src_one'}, {type =>'destination', name => 'dest_one'}] },
	    ],
    };
    
    $comp->setConf( $new_conf );
    
    #my $data = $comp->getConf();
    
    
    my $econtext = EContext::Local->new();
    my $ecomp = EEntity::EComponent::ESyslogng3->new( data => $comp );
    
    $dest_dir = "/tmp/syslog-ng";
    `mkdir $dest_dir` if not -d $dest_dir;
    
    $ecomp->configureNode( econtext => $econtext, mount_point => "/tmp", template_path => ".", motherboard => "" );
    
    use File::Compare;
    
    my $file_compare = File::Compare::compare_text("/tmp/syslog-ng/syslog-ng.conf", "syslog-ng.conf.good");
    is( $file_compare, 0, "Good generated file");
    
    $adm->{db}->txn_rollback;
};
if($@) {
    my $error = $@;
    
    $adm->{db}->txn_rollback;
    print "$error";
    exit 233;
}
