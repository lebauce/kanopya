package LogAnalyzer;

use Data::Dumper;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {};

    bless $self, $class;

    $self->init();

    return $self;
}

# Hardcoded init to handle haproxy logs
sub init {
    my $self = shift;

    my @log_head = qw(month day time sender);

    my @tcp_log_fields = qw(process client accept_date frontend_name backend_name timers bytes_read termination_state conn_info queues);
    @tcp_log_fields = (@log_head, @tcp_log_fields);
    $self->addLogFormat( mode => "tcp", fields => \@tcp_log_fields );

    my @http_log_fields = qw(process client accept_date frontend_name backend_name timers status_code bytes_read req_cookie resp_cookie termination_state conn_info queues req_head resp_head http_request);
    @http_log_fields = (@log_head, @http_log_fields);
    $self->addLogFormat( mode => "http", fields => \@http_log_fields );

    # Define way to switch between modes
    $self->{frontend_name_idx} = scalar(@log_head) + 3; # for tcp and http log, this idx is the same
    # Associate frontend name with its mode (as defined in haproxy configuration)
    $self->{frontends_mode} = {
        "https-in" => "tcp",
        "http-in" => "http",
    };
}

sub addLogFormat {
    my $self = shift;
    my %args = @_;

    my $it = 0;
    my %log_field_idx = map { $_ => $it++ } @{ $args{fields} };
    $self->{'field_idx'}{ $args{mode} } = \%log_field_idx;
}

sub reset {
    my $self = shift;

    print "RESET\n";
    $self->{counters} = {};
}

sub parse {
    my $self = shift;
    my %args = @_;

    print "PARSE : \n", $args{log};

    my @raw = split /\s+/, $args{log};

    my $frontend_name = $raw[ $self->{frontend_name_idx} ];
    my $mode =  $self->{frontends_mode}{ $frontend_name };
    if (not defined $mode) {
        print "Warning: log not analyzed (don't know how to parse it, mode key is '$frontend_name') => @raw\n";
        return;
    }
    my $idx_map = $self->{field_idx}{ $mode };
    
    # Check errors
    my $termination_state = $raw[ $idx_map->{termination_state} ];
    if ( $termination_state !~ '^--' ) { # normal termination state begin with --
        $self->{counters}{ $frontend_name }{'errors'}{ $termination_state } += 1;
        $self->{counters}{ $frontend_name }{'errors'}{'total'} += 1;
        
        if ( $termination_state =~ '^s.*' ) { # server side abort
            $self->{counters}{ $frontend_name }{'server_abort'} += 1;
        }
        return;
    }
    
    # Timers
    my @timers_name = ('Tq', 'Tw', 'Tc', 'Tr'); # + Tt managed separatly
    my @timers = split '/', $raw[ $idx_map->{timers} ];
    for my $idx (0..$#timers_name) {
        $self->{counters}{ $frontend_name }{'timers'}{ $timers_name[$idx] } += $timers[$idx];           
    }
    # manage Tt
    my $Tt = $timers[-1];
    my $total_time;
    if ($Tt =~ /\+(\d+)/) { # haproxy option logasap
        $total_time = $1;
    } else {
        $total_time = $Tt;
    }
    $self->{counters}{ $frontend_name }{'timers'}{'Tt'} += $total_time;

    # Connections
    my @conns = split '/', $raw[ $idx_map->{conn_info} ];
    $self->{counters}{ $frontend_name }{'conns'}{'act'} += $conns[0];

    # Store processed log count
    $self->{counters}{ $frontend_name }{'ok_count'} += 1;

}

sub getStats {
    my $self = shift;

    print Dumper $self->{counters};

    my %stats;
    while (my ($frontend, $info) = each %{$self->{counters}}) {
        if (defined $info->{ok_count}) {
            #$stats{$frontend}{'timers'}{'Tt'} = $info->{'timers'}{'Tt'} / $info->{ok_count};

            while (my ($timer_name, $value) = each %{ $info->{'timers'} }) {
                $stats{$frontend}{'timers'}{$timer_name} = $value / $info->{ok_count};
            } 

            $stats{$frontend}{'timers'}{'num_logs'} = $info->{ok_count};
            $stats{$frontend}{'conns'}{'Active'} = $info->{'conns'}{'act'} / $info->{ok_count};
            $stats{$frontend}{'errors'}{'Total'} = $info->{'errors'}{'total'};
            
            # Considering all errors are logged we can compute abort rate using server error relativly to active connections
            $stats{$frontend}{'experimental_abort_rate'} = $info->{'server_abort'} / $stats{$frontend}{'conns'}{'Active'};
            # or:
            # $stats{$frontend}{'experimental_abort_rate'} = $info->{'server_abort'} / ($info->{'server_abort'} + $stats{$frontend}{'conns'}{'Active'});
        }
    }

    print "#### STATS #####\n", Dumper \%stats;

    return \%stats;
}

1;
