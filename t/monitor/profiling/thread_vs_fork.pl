

use threads;


use Benchmark qw( timethis timethese cmpthese );

my $count = 5000; # => nb iteration
#my $count = -5; # => nb CPU seconds



############# MAIN

#doFork();
bench();
#timeFork();

#################################

sub bench {
    my $res = timethese($count, {
	'thread' => doThreads,
	'fork' => doFork,
			});
    cmpthese $res;
}


sub timeFork {
    timethis( $count, doFork);
}

#############################################################################################"

sub foo {

    my @arr = (1,2,3);

    return \@arr;
}

#################### THREAD

sub doThreads {

    my @threads = ();
    for (1..10) {
	push @threads, threads->create('foo'); 
    }

    foreach my $thr (@threads) {
	my $ret = $thr->join();
	#print "$ret \n"; # pint memory address
    }
}

#################### FORK

sub doFork {
    
    my @childs = ();
    for (1..10) {
	my $pid = fork();
	if ($pid) { #parent
	    push @childs, $pid;
	} elsif ($pid == 0) { #child
	    foo();
	    exit 0;
	} else {
	    die "couldnt fork: $!";
	}
    }
    
    foreach my $child (@childs) {
	my $ret = waitpid($child, 0); # return pid
	#print "$ret \n";
    }
}
