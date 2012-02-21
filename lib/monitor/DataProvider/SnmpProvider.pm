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

SnmpProvider - SnmpProvider object

=head1 SYNOPSIS

    use SnmpProvider;
    
    # Creates provider
    my $provider = SnmpProvider->new( $host );
    
    # Retrieve data
    my $var_map = { 'var_name' => '<snmp_OID>', ... };
    $provider->retrieveData( var_map => $var_map );

=head1 DESCRIPTION

SnmpProvider is used to retrieve snmp var values from a specific host.
Can retrieve value for all OIDs (see snmp MIBs).

=head1 METHODS

=cut

package SnmpProvider;

use strict;
use warnings;
use Net::SNMP;

=head2 new
    
    Class : Public
    
    Desc : Instanciate SnmpProvider instance to provide snmp var values from a specific host
    
    Args :
        host: string: ip of host
    
    Return : SnmpProvider instance
    
=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    # Create snmp session
    my $host = $args{host};
    my ($session, $error) = Net::SNMP->session(
      -hostname  => $host,
      -community => 'my_comnt',
    );

    if (!defined $session) {
      die $error;
    }
    
    $self->{_session} = $session;
    
    return $self;
}


=head2 retrieveData
    
    Class : Public
    
    Desc : Retrieve a set of snmp var value
    
    Args :
        var_map : hash ref : required snmp var { var_name => oid }
    
    Return :
        [0] : time when data was retrived
        [1] : resulting hash ref { var_name => value }
    
=cut

sub retrieveData {
    my $self = shift;
    my %args = @_;

    my $session = $self->{_session};
    my $var_map = $args{var_map};

    my @OID_list = values( %$var_map );
    my $time =time();
    
    my $result = $session->get_request(-varbindlist =>  \@OID_list );        

    if (!defined $result) {
          #$session->close();
        die $session->error();
    }

    my %values = ();
    while ( my ($name, $oid) = each %$var_map ) {
        $values{$name} = $result->{ $oid };    
    }

    return ($time, \%values);
}

sub retrieveTableData {
    my $self =shift;
    my %args = @_;

    my $var_map = $args{var_map};    
    my @columns = map { "$args{table_oid}.1." . $_ } values %$var_map;
    
    if (defined $args{index_oid}) {
        push @columns,  "$args{table_oid}.1." . $args{index_oid};
    }
    
    my $time =time();
    
    my $result = $self->{_session}->get_entries( -columns => \@columns );
    
    my %res = ();
    while ( my ($ds_name, $entry_oid) = each %$var_map ) {
        my $column_oid = "$args{table_oid}.1." . $entry_oid;
        while (my ($res_oid, $value) = each %$result) {
            if ($res_oid =~ /$column_oid\.(.*)/ ) {
                    my $index = $1;
                    $res{$index}{$ds_name} = $value;
            }
        }
    }
    
    # Manage raw indexation with value of a specific column instead of basic indexation (last part of oid)
    my %res_indexed = ();
    if (defined $args{index_oid}) {
        my $index_column_oid = "$args{table_oid}.1." . $args{index_oid};
        while (my ($res_oid, $value) = each %$result) {
            if ($res_oid =~ /$index_column_oid\.(.*)/ ) {
                    my $index = $1;
                    $res_indexed{$value} = $res{$index};
            }
        }
        %res = %res_indexed;
    }
    
    return ($time, \%res);
}

# destructor
sub DESTROY {
    my $self = shift;
    
    # Close session
    my $session = $self->{_session};
    $session->close();
}

1;
