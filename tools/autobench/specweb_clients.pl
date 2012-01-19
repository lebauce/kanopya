#!/usr/bin/perl

# Script that ssh on all specweb client hosts (CLIENTS in Test.config) and start/stop clients

my $SPECWEB_DIR = "/web2005-1.31";

sub getClients {
    my $clients = `grep "^CLIENTS =" $SPECWEB_DIR/Prime_Client/Test.config`;
    my @clients;
    if ($clients =~ /^CLIENTS = \"(.*)\"/) {
	@clients = split ' ', $1;
    } 
    return @clients;
}


sub start {
    for my $client (getClients()) {
	    print "# start client on $client\n";
        
        my $client_cmd = 'ssh root@' . $client . " 'cd $SPECWEB_DIR/Client/ && sh start_client.sh'";
        my $cmd = 'gnome-terminal -e "' . 'ssh root@10.1.1.1 \"' . $client_cmd . '\"" &';
        #print $cmd;        
        system( $cmd );
        
        # Direct access (local ssh public key must be on nodes)	    
        #system( 'gnome-terminal -e "' . 'ssh root@' . $client . " 'cd $SPECWEB_DIR/Client/ && sh start_client.sh'" . '" &');
    }
}
 
sub stop {
    for my $client (getClients()) {
	    print "# stop client on $client\n";
	    
        my $client_cmd = 'ssh root@' . $client . ' \"pgrep -f specwebclient | xargs kill -9\"';
        my $cmd = 'ssh root@10.1.1.1 "' . $client_cmd . '"';
        #print $cmd, "\n";        
        system( $cmd );

        # Direct access (local ssh public key must be on nodes)
	    #system('ssh root@' . $client . ' "pgrep -f specwebclient | xargs kill -9"');
    }
}

$SIG{INT} = \&onKill;

if ($ARGV[0] eq "start") {
    start();
} elsif ($ARGV[0] eq "stop") {
    stop();
} elsif ($ARGV[0] eq "bench") {
    #stop();
    start();
    #print "Press [ENTER] when all client nodes are ready";
    #<STDIN>;
    print "Wait clients before start...\n";
    sleep 10;
    print "# start prime client on localhost\n";
    system("cd $SPECWEB_DIR/Prime_Client && sh start_prime_client.sh");
    #system("cd $SPECWEB_DIR/Prime_Client && sudo sh start_prime_client.sh");
    #system("cd $SPECWEB_DIR/Prime_Client && gnome-terminal -e 'sudo sh start_prime_client.sh' && cd -");

} else {
    print "Need params:\nstart : start all clients\nstop : stop all clients\nbench : start all clients and then start the prime client\n";
}

sub onKill {
    print "\nKill clients\n";
    system( "perl specweb_clients.pl stop" );
    exit;
}

