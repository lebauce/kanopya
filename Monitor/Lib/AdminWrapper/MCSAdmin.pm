package MCSAdmin;

use lib qw(/workspace/mcs/Administrator/Lib);

use strict;
use warnings;
use Administrator;

sub new {
    my $class = shift;
    my %args = @_;

	my $self = {};
	bless $self, $class;

	#$self->{_admin} = Administrator->new( login =>'thom', password => 'pass' );;
	
    return $self;
}

#sub getEntities {
#	my $self = shift;
#	
#	return ($self->{_admin})->getEntities( @_ ); #?
#}

sub retrieveHostsByCluster {
	my $self = shift;
return ();
	my %hosts_by_cluster;

	my $adm = $self->{_admin};
	my @clusters = $adm->getEntities( type => "Cluster", hash => { } );
	foreach my $cluster (@clusters) {
		#my @mb_ip;
		my %mb_info;
		foreach my $mb ( values %{ $cluster->getMotherboards( administrator => $adm) } ) {
			#push @mb_ip, $mb->getAttr( name => "motherboard_internal_ip" );
			
			my $mb_name = $mb->getAttr( name => "motherboard_hostname" );
			my $mb_ip = $mb->getAttr( name => "motherboard_internal_ip" );
			my ($mb_state, $mb_state_time) = $self->_mbState( state_info => $mb->getAttr( name => "motherboard_state" ) );
			
			$mb_info{ $mb_name } = { ip => $mb_ip, state => $mb_state, state_time => $mb_state_time };
		}
		#$hosts_by_cluster{ $cluster->getAttr( name => "cluster_name" ) } = \@mb_ip;
		$hosts_by_cluster{ $cluster->getAttr( name => "cluster_name" ) } = \%mb_info;
	}	
	
	#print Dumper \%hosts_by_cluster;
	
	# TEMPORARY !!
#	%hosts_by_cluster = ( 	"cluster_1" => { 	
#												'node001' => { ip => 'localhost', state => 'up', state_time => time() },
#												'node002' => { ip => '127.0.0.1', state => 'starting', state_time => time() - 600 }
#											},
#							"cluster_2" => {	
#												'node003' => { ip => '192.168.0.123', state => 'down', state_time => time() }
#											} 
#							);
	
	return %hosts_by_cluster;
}

sub getClustersName {
	my $self = shift;

	my @clustersName;

	my $adm = $self->{_admin};
	my @clusters = $adm->getEntities( type => "Cluster", hash => { } );
	@clustersName = map { $_->getAttr( name => "cluster_name" ) } @clusters;
	
	return @clustersName;
}

1;

__END__

sub AUTOLOAD {
	print "==========> AUTOLOAD : $AUTOLOAD\n";
}