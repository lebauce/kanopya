#    Copyright © 2012 Hedera Technology SAS
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

KanopyaDatabaseProvider - KanopyaDatabaseProvider object

=head1 SYNOPSIS

    use KanopyaDatabaseProvider
    
    # Creates provider
    my $provider = KanopyaDatabaseProvider->new( $host );
    
    # Retrieve data
    my $var_map = { 'var_name' => '<Virtual status var name>', ... };
    $provider->retrieveData( var_map => $var_map );

=head1 DESCRIPTION

KanopyaDatabaseProvider is used to retrieve and archive a value from the Kanopya database.
This is used for billing : we keep track of the number of used cores and the amount
of memory dedicated to a service.

=head1 METHODS

=cut

package KanopyaDatabaseProvider;

use strict;
use warnings;
use Log::Log4perl "get_logger";
my $log = get_logger("monitor");

=head2 new
    
    Class : Public
    
    Desc : Instanciate KanopyaDatabaseProvider instance to provide Virtual stat from a specific host
    
    Args :
        host: string: ip of host
    
    Return : KanopyaDatabaseProvider instance
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    $self->{host} = $args{host};
    
    return $self;
}


=head2 retrieveData
    
    Class : Public
    
    Desc : Retrieve a set of monitor var value
    
    Args :
        var_map : hash ref : required  var { var_name => oid }
    
    Return :
        [0] : time when data was retrived
        [1] : resulting hash ref { var_name => value }
    
=cut

sub retrieveData {
    my $self = shift;
    my %args = @_;

    my $host = $self->{host};
    my $var_map = $args{var_map};

    my @OID_list = values( %$var_map );
    my $time = time();

    my %values = (
        "Cores"  => $host->host_core,
        "Memory" => $host->host_ram
    );

    return ($time, \%values);
}

sub compute {
    my $self = shift;
    my %args = @_;
    
    my $var = $args{var};
    my $load = $args{load};
    
    die "Error: no definition to compute virtual var '$args{var}'";
}

# destructor
sub DESTROY {
}

1;
