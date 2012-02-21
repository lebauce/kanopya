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

=head1 NAME

FuncProvider - FuncProvider object

=head1 SYNOPSIS

    use FuncProvider;
    
    # Creates provider
    my $provider = FuncProvider->new( $host );
    
    # Retrieve data
    my $var_map = { 'var_name' => 'var_name', ... };
    $provider->retrieveData( var_map => $var_map );

=head1 DESCRIPTION

    This provider generate values for a set of metrics according to a node dependent conf.
    Value is generated using a specified function and parameters.
    These settings specified for each node independently, using a configuration file named funcprovider.conf.
    
    Here a sample of a funcprovider.conf file:
        <nodes>
            <node ip='10.0.0.1'>
                <var label='metric1' func='const' value='42'/>
                <var label='metric2' func='random' min='10' max='100'/>
            </node>
            <node ip='10.0.0.2'>
                <var label='metric1' func='const' value='100'/>
                <var label='metric2' func='random' min='20' max='50'/>
            </node>
        </nodes>

    Here the list of allowed function and there parameters
    
    * const (value)
        => return value
    
    * linear (a,b)
        => return a*x + b
        with x the time elapsed since <time ref>
    
    * random (min,max)
        => return rand(min,max)
        
    * sinus (max, period)
    
=head1 METHODS

=cut

package FuncProvider;

#use strict;
use warnings;
use XML::Simple;
use General;
#use Data::Dumper;

use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("collector");

my %funcs = (     
                "const"         => \&const,
                "linear"        => \&linear,
                "sinus"         => \&sinus,
                "custom_sinus"  => \&custom_sinus,
                "random"        => \&random,
            );

my $timeref;

=head2 new
    
    Class : Public
    
    Desc : Instanciate FuncProvider instance to provide Func stat from a specific host
    
    Args :
        host: string: ip of host
    
    Return : FuncProvider instance
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;


    my $host = $args{host};

    $self->{_host} = $host;
    #$self->{_start_time} = time();
    
#    my $file = "/tmp/funcprovider.timeref";
#    my $timeref;
#    if ( -e $file ) {
#        open FILE, "<$file";
#        $timeref = <FILE>;
#        close FILE;
#    } else {
#        $timeref = time();
#        open FILE, ">$file";
#        print FILE $timeref;
#        close FILE;
#    }
#    $self->{_timeref} = $timeref;
#    
    $timeref = time() if (not defined $timeref);
    $self->{_timeref} = $timeref;
    
    
    # Load conf
    my $conf = XMLin("/opt/kanopya/conf/funcprovider.conf");
    my $nodes = General::getAsArrayRef( data => $conf, tag => 'node' );
    my @node_conf = grep { $_->{ip} eq $host } @{ $nodes };
    my $node_conf = shift @node_conf;
    
    die "No host defined : '$host'" if ( not defined $node_conf ); 
    
    
    $self->{_vars} = General::getAsArrayRef( data => $node_conf, tag => 'var' );
        
    return $self;
}

sub sinus {
    my $self = shift;
    
    return $self->custom_sinus(@_);
}

sub const {
    my $self = shift;
    my %args = @_;
    
    return $args{var}{value} || 0;
}

sub random {
    my $self = shift;
    my %args = @_;
    
    my $var = $args{var};
    
    my $rand = rand( $var->{max} - $var->{min} ) + $var->{min};
    
    return $rand;
}

sub custom_sinus {
    my $self = shift;
    my %args = @_;
    
    my $dt = $args{dt};
    my $var = $args{var};
    
    my $max = $var->{max};
    my $dephasage = $var->{dephasage} || 0;
    my $period = $var->{period};
    my $plate_time = $var->{plate_time} || 0;
    my $min_plate_time = 60;
    
    my $sin_period = $period - $plate_time;
    
    my $res;
    my $dt_mod = ($dt + $dephasage) % ($sin_period + $plate_time);
    if ( $dt_mod >= $sin_period / 4 && $dt_mod < $plate_time + ($sin_period / 4) ) {
        $res = $max;
    } else {
        $dt_mod -= $dt_mod < $sin_period / 4 ? 0 : $plate_time;
        my $norme_dt = $dt_mod / $sin_period;
        my $rad = $norme_dt * 2 * 3.1415;

        my $sin = sin $rad;
        $res =  $sin > 0 ? $sin : 0;
        $res *= $max;
    }

    return $res;
}

sub linear {
    my $self = shift;
    my %args = @_;
    
    my $x = $args{dt};
    my $var = $args{var};
    
    my $res = $x * $var->{a} + ( $var->{b} || 0 );
    
    return $res;
}

=head2 retrieveData
    
    Class : Public
    
    Desc : 
    
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

    my $time = time();
    my $dt = $time - $self->{_timeref};
    
    my %values = ();
    for my $var_name (keys %$var_map) {
    
        my @var = grep { $_->{label} eq $var_name } @{ $self->{_vars} };
        my $var = shift @var;
        die "var not found for '$self->{_host} : '$var_name'" if (not defined $var);

        my $func_name = $var->{func};
        my $func = $funcs{$func_name};
        die "Undefined generator func: '$func_name'. Allowed func are: " . join(", ", keys %funcs) if (not defined $func);
        my $res = $func->( $self, dt => $dt, var => $var );

        $values{ $var_name } = $res; 
    }
    
    return ($time, \%values);
}


# destructor
sub DESTROY {
}

1;
