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


=pod
=begin classdoc

MySqlProvider is used to retrieve MySql status values from a specific host.

All var name: '> mysqladmin extented-status' or 'mysql> show status;'
For more details see http://dev.mysql.com/doc/refman/5.0/en/server-status-variables.html

# Creates provider
my $provider = MySqlProvider->new( $host );

# Retrieve data
my $var_map = { 'var_name' => '<MySql status var name>', ... };
$provider->retrieveData( var_map => $var_map );

=end classdoc
=cut

package DataProvider::MySqlProvider;

use strict;
use warnings;
use base 'DataProvider';
use DBI;

use Log::Log4perl "get_logger";
my $log = get_logger("");


=pod
=begin classdoc

@constructor

Instanciate MySqlProvider instance to provide MySql stat from a specific host

@param host: string: ip of host

@return MySqlProvider instance

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};
    bless $self, $class;

    my $host = $args{host};

    # TODO user/pwd management to connect to a component providing informations
    my $dbh = DBI->connect("dbi:mysql:mysql:" . $host->adminIp . ":3306",
                           'root', 'Hedera@123') or die DBI::errstr();

    $self->{_dbh} = $dbh;
    $self->{_host} = $host;

    return $self;
}


=pod
=begin classdoc

Retrieve a set of mysql status var value

@param var_map : hash ref : required  var { var_name => oid }

@return [0] : time when data was retrived or [1] : resulting hash ref { var_name => value }

=end classdoc
=cut

sub retrieveData {
    my $self = shift;
    my %args = @_;

    my $var_map = $args{var_map};

    my $sth  = $self->{_dbh}->prepare("SHOW GLOBAL STATUS;");
    $sth->execute();
    my $time =time();


    my %status;
    while( my ($key, $val) = $sth->fetchrow_array()) {
        $status{$key} = $val;
    }

    my %values = ();
    while ( my ($name, $oid) = each %$var_map ) {
        if (exists $status{$oid}) {
            $values{$name} = $status{$oid};
        } else {
            $log->warn("oid '$oid' not found in MySql status.");
            $values{$name} = undef;
        }
    }

    return ($time, \%values);
}

# destructor
sub DESTROY {
}

1;
