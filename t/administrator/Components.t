#!/usr/bin/perl -w
use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Kanopya::Exceptions;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level=>'DEBUG', layout=>'%F %L %p %m%n'});
use Data::Dumper;

use_ok ('Administrator');
use_ok ('Entity::Component::Apache2');

eval {
	#BEGIN { $ENV{DBIC_TRACE} = 1 }
	Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
	my $adm = Administrator->new;
	print "\n----------------------------------------------------\n";
	my $apache2 = Entity::Component::Apache2->new(
		apache2_serverroot => '/www',
		apache2_loglevel   => 'debug',
		apache2_ports      => '80',
		apache2_sslports   => '',
		component_type_id => 2
	);
	
};

#~ eval {
	#~ BEGIN { $ENV{DBIC_TRACE} = 1 }
	#~ Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
	#~ my $adm = Administrator->new;
	#~ print "\n----------------------------------------------------\n";
	#~ my $db = $adm->{db};
	#~ my $attrs = {
		#~ component => { 
			#~ component_type_id => 2,
			#~ apache2 => {
				#~ apache2_serverroot => '/www',
				#~ apache2_loglevel   => 'debug',
				#~ apache2_ports      => '80',
				#~ apache2_sslports   => '',
			#~ }
		#~ }
	#~ };
	#~ 
	#~ my $r1 = $db->resultset('Entity')->new($attrs);	
	#~ $r1->insert;
	#~ my $id = $r1->id;
	#~ print "ID: $id\n";
	#~ $r1 = $db->resultset('Apache2')->find($id);
	#~ $r1->parent->set_column(cluster_id => 1);
	#~ 
	#~ $r1->parent->update;
	#~ print Dumper(ref($r1->parent));
	#~ print Dumper(ref($r1));
	#~ 
	#~ #my $r2 = $db->resultset('Entity')->new($attrs);
	#~ #$r2->insert;
	#~ 
#~ };


#~ eval {
    #~ BEGIN { $ENV{DBIC_TRACE} = 1 }
    #~ Administrator::authenticate( login =>'admin', password => 'K4n0pY4' );
#~ 
	#~ my $adm = Administrator->new();
#~ 
	#~ my $cluster = Entity::Cluster->getCluster(hash => { cluster_name => 'adm' });
#~ 
	#~ my %attrs = (
		#~ apache2_serverroot => '/www',
		#~ apache2_loglevel   => 'debug',
		#~ apache2_ports      => '80',
		#~ apache2_sslports   => '',
		#~ component_type_id  => 2,
	#~ );
	#~ 
		#~ 
	#~ 
	#~ my $apache2 = Entity::Component::Apache2->new(%attrs);
	#~ 
	#~ 
	#~ #$apache2->save();
	#~ #$cluster->addComponent(component => $apache2);
	#~ 
#~ };




if($@) {
	my $error = $@;
	print Dumper $error;
};

