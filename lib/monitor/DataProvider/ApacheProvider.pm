
=head1 NAME

ApacheProvider - ApacheProvider object

=head1 SYNOPSIS

    use ApacheProvider;
    
    # Creates provider
    my $provider = ApacheProvider->new( $host );
    
    # Retrieve data
    my $var_map = { 'var_name' => '<apache status var name>', ... };
    $provider->retrieveData( var_map => $var_map );

=head1 DESCRIPTION

ApacheProvider is used to retrieve apache status values from a specific host.
Apache status var names correspond to strings before ":" displayed in apache status page (see http://$host/server-status?auto)  

=head1 METHODS

=cut

package ApacheProvider;

use strict;
use warnings;
use Log::Log4perl "get_logger";
my $log = get_logger("monitor");

=head2 new
    
    Class : Public
    
    Desc : Instanciate ApacheProvider instance to provide apache stat from a specific host
    
    Args :
        host: string: ip of host
    
    Return : ApacheProvider instance
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;


    my $host = $args{host};
    my $component = $args{component};
    
    # Retrieve the apache port which doesn't use ssl
    my $net_conf = $component->getNetConf();
    my ($port, $protocols);
    while(($port, $protocols) = each %$net_conf) {
        last if (0 == grep {$_ eq 'ssl'} @$protocols );
    }
    
    my $cmd =     'curl -A "mozilla/4.0 (compatible; cURL 7.10.5-pre2; Linux 2.4.20)"';
    $cmd .=        ' -m 12 -s -L -k -b /tmp/bbapache_cookiejar.curl';
    $cmd .=        ' -c /tmp/bbapache_cookiejar.curl';
    $cmd .=        ' -H "Pragma: no-cache" -H "Cache-control: no-cache"';
    $cmd .=        ' -H "Connection: close"';
    $cmd .=        " $host:$port/server-status?auto";
    
    $self->{_cmd} = $cmd;
    $self->{_host} = $host;
    
    return $self;
}


=head2 retrieveData
    
    Class : Public
    
    Desc : Retrieve a set of apache status var value
    
    Args :
        var_map : hash ref : required  var { var_name => oid }
    
    Return :
        [0] : time when data was retrived
        [1] : resulting hash ref { var_name => value }
    
=cut

sub retrieveData {
    my $self = shift;
    my %args = @_;

    my $var_map = $args{var_map};

    my @OID_list = values( %$var_map );
    my $time =time();

    my $server_status = qx( $self->{_cmd} );
    
    if ( $server_status eq "" ) {
        die "No response from remote host : '$self->{_host}' ";
    }
    if ( $server_status =~ "403 Forbidden" ) {
        die "You don't have permission to access $self->{_host}/server_status";
    }
    

    my %values = ();
    while ( my ($name, $oid) = each %$var_map ) {
        my $value;
        if ($server_status =~ /$oid: ([\d|\.]+)/i ) {
            $value = $1 || 0;
        }
        else
        {
            $value = undef;
            $log->warn("oid '$oid' not found in Apache status.");
        }
        $values{$name} = $value;
    }
    
    return ($time, \%values);
}

# destructor
sub DESTROY {
}

1;
