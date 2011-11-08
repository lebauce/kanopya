#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
package Model::MVAModel;

use strict;
use warnings;
use Data::Dumper;
use List::Util qw(min max sum);
use Log::Log4perl "get_logger";
my $log = get_logger("MVAModel");

use base "Model";

sub new {
    my $class = shift;
    my %args = @_;
    
    my $self = {};
    bless $self, $class;
    
    return $self;
}

=head2 calculate

B<Class>   : Public
B<Desc>    : Estimate qos according to infrastructure configuration and workload
B<args>    : configuration : hash ref { 
                M => nb tiers
                AC => array of nb node for each tier
                LC => array of MPL value for each tier
             }
             workload_class : hash ref {
                visit_ratio
                service_time
                delay
                think_time
             }
             workload amount : int
B<Return>  : hash : (
                latency => $latency,        # ms
                abort_rate => $abort_rate,  # %
                throughput => $throughput,  # req/sec
            )
B<Comment>  : Adapted from Jean Arnaud model
B<throws>  : None

=cut

sub calculate {
    
    my $self = shift;
    my %args = @_;
    
    
    #print Dumper $args{workload_class};
    my $M   = $args{configuration}{M};
    
    
    my @AC  = @{ $args{configuration}{AC} };
    my @LC  = @{ $args{configuration}{LC} };
    
    
    my @V   = @{ $args{workload_class}{visit_ratio} };  # Visit ratio
    my @S   = @{ $args{workload_class}{service_time} }; # Service time
    my @D   = @{ $args{workload_class}{delay} };        # Delay (communication between tiers)
    my $Z   = $args{workload_class}{think_time};        # Think time       
    
    my $workload_amount = $args{workload_amount};
    
#    print "Visit ratio = @V\n";
#    print "S = @S\n";
#    print "S = @D\n";    
#    print "AC = @AC\n";
#    print "LC = @LC\n";
    
  
    
    # assert
    die "## ASSERT: MVAModel: no workload amount\n" if ( not defined $workload_amount );
    die "## ASSERT: MVAModel: workload_class->think_time must be > 0\n" if ( $Z <= 0 );
    
    
    ####
    # Calculate the entering admission control
    ####
    
    my @Nt  = (); # Total requests entering a tier
    my @Na  = (); # Accepted requests per tier (Ti)
    my @Nap = (); # Accepted requests at Ti..Tm
    my @Nr  = (); # Rejected requests per tier
    my @MPL = (); # Total MPL per tier
    
    for my $i (0 .. $M-1) {
        $Nt[$i] =   ($i == 0) ? $workload_amount
                    : min(     $Na[$i-1], $Na[$i-1] * $V[$i] / $V[$i - 1] );
                        
        $MPL[$i] = $LC[$i] * $AC[$i]; # Considering all nodes have the same LC for a tier
        
        $Na[$i] = min( $MPL[$i], $Nt[$i]);
        $Nr[$i] = $Nt[$i] - $Na[$i];
    }
    
    for my $i (0 .. $M-1) {
        $Nap[$i] = $Na[$i] - (sum( @Nr[$i+1 .. $M-1] ) || 0);
    }
        
    my $N_rejected = sum @Nr;
    my $N_admitted = $workload_amount - $N_rejected;
    
    #print ">>> Admitted : $N_admitted / $workload_amount\n";
    
    #####
    # Service latency
    #####
    
    my @Ql  = (); # Total queue length per tier
    my @W   = (); # Service demand per tier
    my @R   = (); # Response time of request admitted per tier
    my @La  = (); # Latency of request admitted at Ti ..TM
    my @Lr  = (); # Latency of request admitted at Ti and rejected at Ti+1 ..TM
    my @Ta  = (); # Throughput of request admitted at Ti ..TM
    my @Tr  = (); # Throughput of request admitted at Ti and rejected at Ti+1 ..TM
    
    
    for my $i (0 .. $M-1) {
        $Ql[$i] = 0;
        $W[$i] = ($S[$i] - $D[$i]) * $V[$i];
    }
    
#    print "M = $M, $Na[0], $Na[1]\n";
#    my $a = <>;
    
    # TODO study this part (difference between pseudo-code in thesis and moka implementation)
    for (my $i = $M - 1; $i >= 0; $i--) {
        
        # Client insertion
        #for (my $j = 1; $j < $Na[$i]; $j++) {
        for (my $j = 1; $j <= $Na[$i]; $j++) {
            my $Wip = (1 + $Ql[$i]) * $W[$i] / $AC[$i]; # Service demand per node at Ti
   
            $R[$i] = max( $Wip, $W[$i] ) + ( $D[$i] * $V[$i] );  
            
            
            if ($i < $M - 1) {
                    #print "$i $j $R[$i]+ $La[$i + 1] La[$i + 1]\n";
                    $La[$i] = $R[$i] + $La[$i + 1];
                    $Lr[$i] = $R[$i] + $Lr[$i + 1];
            } else {
                $La[$i] = $R[$i];
                $Lr[$i] = $R[$i];
            }
            
            
            
            # /!\ WARNING /!\ Potential cast problem in the original java algo ?
            $Ta[$i] = ($j * $Nap[$i] / $Na[$i]) / ($La[$i] + $Z);
            $Tr[$i] = ($j * ($Na[$i] - $Nap[$i])/ $Na[$i]) / ($Lr[$i] + $Z);
             
            #$Ql[$i] = ($Ta[$i] + $Tr[$i]) * $R[$i]; # Ti’s total queue length with Little’s law
            #Compliance with MOKA code
            $Ql[$i] = int(($Ta[$i] + $Tr[$i]) * $R[$i]);
        }
        #print "La[$i] = $La[$i]\n";
    }
   
    my $latency = $La[0];
        
    ######
    #  Service throughput and abandon rate
    ######
    
    my $Ta_total = $N_admitted / ($La[0] + $Z);    # throughput of requets admitted at T1 ..TM <=> total throughput    
    my $Tr_total = $Nr[0] / $Z;    # throughput of requets admitted at T1 and rejected at T2 ..TM
    my $Trp = ($N_rejected - $Nr[0]) / ($Lr[0] + $Z); # throughput of requests rejected at T1
    my $abort_rate = ($Tr_total+$Trp)/($Tr_total+$Trp+$Ta_total); # total abandon rate 
    
    
    #Log all intermediate values in order to compare to J.Arnaud's MOKA (Java) algorithm
    my $log_string = ">>>> Valeurs intermédiaires : \n"
    ."Nadm = $N_admitted\n"
    ."Nrej = $N_rejected\n"
    ."Nr = @Nr\n"
    ."La = @La\n"
    ."Tr = $Tr_total \n"
    ."Trp = $Trp \n"
    ."Ta = $Ta_total\n";
    
    $log->debug($log_string);
    
    #my $throughput = 1000 * $Ta_total; # Jean arnaud thesis throughput -> aberrant result
    my $throughput = $Ta_total;
    #my $throughput = ( 1 / $latency );  # Alternative throughput -> works for open network but not for our case (closed network)
                                        # TO STUDY
    
    return (
        latency => $latency,              # ms (mean time for execute client request)
        abort_rate => $abort_rate,        # %  (rejected_request/total_request)
        throughput => $throughput,        # req/sec (successful requests per sec) = reply rate?
    );    
}

1;
