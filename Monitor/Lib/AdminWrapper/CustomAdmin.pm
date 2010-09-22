package CustomAdmin;

use strict;
use warnings;
use XML::Simple;
use General;

use Data::Dumper;

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	#$self->{_ref} = { ref1 => [], ref2 => [] };

    return $self;
}

sub retrieveHostsByCluster {
	my $self = shift;

	my $conf = XMLin("/workspace/mcs/Monitor/Conf/nodes.conf");
	my $clusters = $conf->{clusters};#General::getAsHashRef( data => $conf, tag => 'cluster', key => 'label' );
	
	#print Dumper $clusters;
	
	return %$clusters;
	
#	my %hosts_by_cluster = ( 	"cluster_1" => { 	
#												'node001' => { ip => 'localhost', state => 'up'},
#												'node002' => { ip => '127.0.0.1', state => 'up' }
#											},
#								"cluster_2" => {	
#												'node003' => { ip => '192.168.0.123', state => 'down' }
#											} 
#							);
#	
#	return %hosts_by_cluster;
}

sub getClustersName {
	my $self = shift;

	my $conf = XMLin("/workspace/mcs/Monitor/Conf/nodes.conf");
	my $clusters = $conf->{clusters};
	
	my @clustersName = keys %$clusters;
	
	return @clustersName;
}

sub getEntities {
	return ();
}

1;