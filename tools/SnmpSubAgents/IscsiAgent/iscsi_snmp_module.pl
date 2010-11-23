use NetSNMP::OID (':all'); 
use NetSNMP::agent (':all'); 
use NetSNMP::ASN (':all');

print "ISCSI agent!\n";

my $rootOID = ".1.3.6.1.3.1";

    #
    # Handler routine to deal with SNMP requests
    #
sub iscsi_mib_handler {
    my  ($handler, $registration_info, $request_info, $requests) = @_;

    print "iscsi handling..\n";
    
    my @initiator_table_def = 
	( { id => 17, stat_name => 'rxdata_octets', type => ASN_COUNTER }, #rxInitiatorDataBytes  ==> WARNING: type should be ASN_COUNTER64 but didn't work with it, try to use Math::Int64
	  { id => 30, stat_name => 'txdata_octets', type => ASN_COUNTER }, #txInitiatorDataBytes
	);


   # Get iscsi info
    my %oid_info = ();
    
    my $session = `sudo iscsiadm -m session`;
    my @sessions = split "\n", $session;

    my %session_info = ();
    foreach $session (@sessions) {
	if ($session =~ /.*\[([\d]+)\].*/)
	{
	    my $sid = $1;
	    $session_info{$sid} = `sudo iscsiadm -m session -r $sid --stats`;
	}
    }
    my $nb_sessions = scalar keys %session_info;

    my $curr_oid = new NetSNMP::OID($rootOID . ".1.1.1");
    $oid_info{$curr_oid}{value} = $nb_sessions;
    $oid_info{$curr_oid}{type} = ASN_UNSIGNED;

    my $prev_oid = $curr_oid;
    my $tableOID = "1.1.6";
    my $table_first_oid;
    foreach my $col_def ( @initiator_table_def ) {
	my $first_index = undef;
	while ( my ($index, $stats) = each %session_info ) {
	    if ( $stats =~ /$col_def->{stat_name}: ([\d]+)/) {
		$first_index = $index if not defined $first_index;
		my $value = $1;
		$curr_oid = new NetSNMP::OID($rootOID . "." . $tableOID . ".1." . $col_def->{id} . "." . $index);
		#use Math;
		#$oid_info{$curr_oid}{'value'} = Math::Int64($value);
		$oid_info{$curr_oid}{'value'} = $value;
		$oid_info{$curr_oid}{'type'} = $col_def->{type};
		$oid_info{$prev_oid}{'next'} = $curr_oid;
		$prev_oid = $curr_oid;
	    }
	}
	if (defined $first_index) {
	    my $col_oid = new NetSNMP::OID($rootOID . "." . $tableOID . ".1." . $col_def->{id});
	    $oid_info{$col_oid}{'next'} = new NetSNMP::OID($rootOID . "." . $tableOID . ".1." . $col_def->{id} . "." . $first_index);
	    
	    if (not defined $table_first_oid) { $table_first_oid = $col_def->{id} . "." . $first_index; }
	}
    }

    for ($request = $requests; $request; $request = $request->next()) {

        #
        #  Work through the list of varbinds
        #
	my $oid = new NetSNMP::OID($request->getOID());
	print "   oid : $oid\n";
	if ($request_info->getMode() == MODE_GET) {
	    if (exists $oid_info{$oid} && defined $oid_info{$oid}{value}) {
		$request->setValue( $oid_info{$oid}{type}, $oid_info{$oid}{value});
	    }
	} elsif ($request_info->getMode() == MODE_GETNEXT) {

	    if (defined($oid_info{$oid}) && defined($oid_info{$oid}{'next'})) { 
		my $next_oid = $oid_info{$oid}{'next'};
		$request->setOID( $next_oid );
		$request->setValue( $oid_info{$next_oid}{type}, $oid_info{$next_oid}{value} ); 
	    } elsif ($oid <= new NetSNMP::OID($rootOID)) { 
		my $next_oid = new NetSNMP::OID($rootOID . '.1.1.1');
		$request->setOID( $next_oid );
		$request->setValue( $oid_info{$next_oid}{type}, $oid_info{$next_oid}{value} );
	    } elsif ($oid <= new NetSNMP::OID($rootOID . "." . $tableOID . '.1')) {
		my $next_oid = new NetSNMP::OID($rootOID .'.' .  $tableOID . '.1.' . $table_first_oid);
		if (defined $oid_info{$next_oid}) {
		    $request->setOID( $next_oid );
		    $request->setValue( $oid_info{$next_oid}{type}, $oid_info{$next_oid}{value} );
		}
	    }
	}

    }
}


{
    #
    # Associate the handler with a particular OID tree
    #
    my $regoid = new NetSNMP::OID($rootOID); 
    $agent->register("iscsi_agent", $regoid, \&iscsi_mib_handler);
}

