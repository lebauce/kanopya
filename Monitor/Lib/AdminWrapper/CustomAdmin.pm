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

    return $self;
}

sub getEntities { 
	my $self = shift;
	my %args = @_;
	
	if ( $args{type} eq "Motherboard" ) {
		my $req = $args{hash};
		if ( exists $req->{motherboard_state} && $req->{motherboard_state} eq "down" ) {
			
			open POOL, "</tmp/virtual_pool.adm" || die "can't open virtual pool file";
			my @hosts = <POOL>;
			close POOL;
	
			my $host = shift @hosts;
			if ( defined $host ) {
				chomp( $host );
				return ($host);
			}
			return ();
		} elsif ( exists $req->{motherboard_internal_ip} ) {
			
			return $req->{motherboard_internal_ip};
		}
		return ();
	}
	if ( $args{type} eq "Cluster" ) {
		my $clust_name = $args{hash}{cluster_name};
		return defined $clust_name ? ($clust_name) : ();
	}
	
	#print "!!!!!!!!!!!!!!  Not Implemented: getEntities for : ", Dumper \%args; 
	
	return ();
}

sub getOperations {
		my $self = shift;
		
		return [];
}

#sub newOp { my $self = shift; return ($self->{_admin})->newOp( @_ ); }
#sub addMessage { my $self = shift; return ($self->{_admin})->addMessage( @_ ); }


sub opAdd {
	my $self = shift;
	my %args = @_;
	
	open POOL, "</tmp/virtual_pool.adm";
	my @hosts = <POOL>;
	my $host = shift @hosts;
	close POOL;
	open POOL, ">/tmp/virtual_pool.adm";
	print POOL @hosts;
	close POOL;
	
	open CLUST, ">>/tmp/virtual_cluster_$args{cluster}.adm";
	chomp($host);
	print CLUST "$host up\n";
	close CLUST;
	
	print "ADD =============> asked: $args{motherboard} | added: $host\n";
}

sub opRemove {
	my $self = shift;
	my %args = @_;
	
	open CLUST, "</tmp/virtual_cluster_$args{cluster}.adm";
	my @hosts = <CLUST>;
	my $host = pop @hosts; # always remove the last node of the file (the more rescently added)
	close CLUST;
	open CLUST, ">/tmp/virtual_cluster_$args{cluster}.adm";
	print CLUST @hosts;
	close CLUST;
	
	open POOL, ">>/tmp/virtual_pool.adm";
	chomp($host);
	my ($ip) = split " ", $host; 
	print POOL "$ip\n";
	close POOL;
	
	print "REMOVE =============> asked: $args{motherboard} | removed: $host ($ip)\n";
}

sub getClusterMasterNodeIp {
	my $self = shift;
	my %args = @_;

	return 0;
}

sub getClusterId {
	return 0;
}

sub retrieveHostsByCluster {
	my $self = shift;

#	my $conf = XMLin("/workspace/mcs/Monitor/Conf/nodes.conf");
#	my $clusters = $conf->{clusters};#General::getAsHashRef( data => $conf, tag => 'cluster', key => 'label' );
#	
#	#print Dumper $clusters;
#	
#	return %$clusters;
	
	my %hosts_by_cluster = ();
	
	my $dir = "/tmp";
	opendir DIR, $dir or die "$dir doesn't exist !";
	my @files = readdir DIR;
	for my $file (@files) {
		if ( $file =~ /^virtual_cluster_([a-zA-Z0-9_]+).adm/ ) {
			my $clust_name = $1;
			my %hosts = ();
			open FILE, "<$dir/$file" || die "can't open file $file!";
			while ( <FILE> ) {
				my $line = $_;
				chomp $line;
				my ($node_ip, $node_state) = split ' ', $line;
				$hosts{"node_$node_ip"} = { ip => $node_ip, state => $node_state };
			}
			close FILE;
			$hosts_by_cluster{ $clust_name } = \%hosts;
		}
	}
	closedir DIR;
	
	return %hosts_by_cluster;
	
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

#	my $conf = XMLin("/workspace/mcs/Monitor/Conf/nodes.conf");
#	my $clusters = $conf->{clusters};
#	
#	my @clustersName = keys %$clusters;
	
	my @clustersName = ();
	my $dir = "/tmp";
	opendir DIR, $dir or die "$dir doesn't exist !";
	my @files = readdir DIR;
	for my $file (@files) {
		if ( $file =~ /^virtual_cluster_([a-zA-Z0-9_]+).adm/ ) {
			push @clustersName,  $1;
		}
	}
	close DIR;
	
	#print "===> CLUSTER NAMES : @clustersName\n";
	
	return @clustersName;
}


1;