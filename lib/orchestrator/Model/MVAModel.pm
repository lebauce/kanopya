package Model::MVAModel;

use strict;
use warnings;
use Data::Dumper;
use List::Util qw(min max sum);

use base "Model";

sub new {
    my $class = shift;
    my %args = @_;
	
	my $self = {};
	bless $self, $class;
	
    return $self;
}

sub calculate {
	my $self = shift;
    my %args = @_;
    
	print "MVAModel CALCULATE\n";
	
	my $M 	= $args{configuration}{M};
	my @AC 	= @{ $args{configuration}{AC} };
	my @LC 	= @{ $args{configuration}{LC} };
	
	my @V 	= @{ $args{workload_class}{visit_ratio} }; 	# Visit ratio
	my @S	= @{ $args{workload_class}{service_time} };	# Service time
	my @D	= @{ $args{workload_class}{delay} };		# Delay (communication between tiers)
	my $Z   = $args{workload_class}{think_time};		# Think time
	
	my $workload_amount = $args{workload_amount};
	
	# assert
	if ( $Z <= 0 ) {
		print "Assert: MVAModel: workload_class->think_time must be > 0\n";
	}
	
	####
	# Calculate the entering admission control
	####
	
	my @Nt 	= (); # Total requests entering a tier
	my @Na 	= (); # Accepted requests per tier (Ti)
	my @Nap = (); # Accepted requests at Ti..Tm
	my @Nr 	= (); # Rejected requests per tier
	my @MPL = (); # Total MPL per tier
	
	for my $i (0 .. $M-1) {
		$Nt[$i] = 	($i == 0) ? $workload_amount
					: min( 	$Na[$i-1], $Na[$i-1] * $V[$i] / $V[$i - 1] );
						
		$MPL[$i] = $LC[$i] * $AC[$i]; # Considering all nodes have the same LC for a tier
		
		$Na[$i] = min( $MPL[$i], $Nt[$i]);
		$Nr[$i] = $Nt[$i] - $Na[$i];
	}
	
	for my $i (0 .. $M-1) {
		$Nap[$i] = $Na[$i] - (sum( @Nr[$i+1 .. $M-1] ) || 0);
	}
		
	my $N_rejected = sum @Nr;
	my $N_admitted = $workload_amount - $N_rejected;
	
	#####
	# Service latency
	#####
	
	my @Ql 	= (); # Total queue length per tier
	my @W 	= (); # Service demand per tier
	my @R	= (); # Response time of request admitted per tier
	my @La	= (); # Latency of request admitted at Ti ..TM
	my @Lr	= (); # Latency of request admitted at Ti and rejected at Ti+1 ..TM
	my @Ta	= (); # Throughput of request admitted at Ti ..TM
	my @Tr	= (); # Throughput of request admitted at Ti and rejected at Ti+1 ..TM	
	
	for my $i (0 .. $M-1) {
		$Ql[$i] = 0;
		$W[$i] = ($S[$i] - $D[$i]) * $V[$i];
	}
	
	# TODO study this part (difference between pseudo-code in thesis and moka implementation)
	for (my $i = $M - 1; $i >= 0; $i--) {
		# Client insertion
		#for (my $j = 1; $j < $Na[$i]; $j++) {
		for (my $j = 1; $j <= $Na[$i]; $j++) {
			my $Wip = (1 + $Ql[$i]) * $W[$i] / $AC[$i]; # Service demand per node at Ti
			$R[$i] = max( $Wip, $W[$i] ) + ( $D[$i] * $V[$i] );
			
			if ($i < $M - 1) {
				$La[$i] = $R[$i] + $La[$i + 1];
				$Lr[$i] = $R[$i] + $Lr[$i + 1];
			} else {
				$La[$i] = $R[$i];
				$Lr[$i] = $R[$i];
			}
			$Ta[$i] = ($j * $Nap[$i] / $Na[$i]) / ($La[$i] + $Z);
			$Tr[$i] = ($j * ($Na[$i] - $Nap[$i])/ $Na[$i]) / ($Lr[$i] + $Z);
				
			$Ql[$i] = ($Ta[$i] + $Tr[$i]) * $R[$i]; # Ti’s total queue length with Little’s law
		}
	}

	my $latency = $La[0];		
		
	######
	#  Service throughput and abandon rate
	######
	my $Ta = $N_admitted / ($La[0] + $Z);	# throughput of requets admitted at T1 ..TM <=> total throughput
	my $Tr = $Nr[0] / $Z;	# throughput of requets admitted at T1 and rejected at T2 ..TM
	my $Trp = ($N_rejected - $Nr[0]) / ($Lr[0] + $Z); # throughput of requests rejected at T1
	my $abort_rate = ($Tr+$Trp)/($Tr+$Trp+$Ta); # total abandon rate 
	
	
	return (
		latency => $latency,			# ms (mean time for execute client request)
		abort_rate => $abort_rate,		# %  (rejected_request/total_request)
		throughput => 1000 * $Ta,		# req/sec (successful requests per sec) = reply rate?
	);	
}

1;
