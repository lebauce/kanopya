#    Copyright © 2013 Hedera Technology SAS
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

package OpenStack::Service;

use OpenStack::Object;
use General;
use Kanopya::Exceptions;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ "name", "api" ]);

    return bless \%args;
}

# First AUTOLOAD() doesn't include args, they will be transmitted to OsObject.AUTOLOAD()
sub AUTOLOAD {
    my ($self, %args) = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];

    return OpenStack::Object->new(service => $self)->$method(%args);
}

# $os_api->tenant(id => '2abdf3')->servers->detail <---> 2abdf3/servers/detail
# tenant(id) is replaced by id of tenant
sub tenant {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { id => $self->{api}->{tenant} });

    return OpenStack::Object->new(path    => $args{id},
                                  service => $self);
}

sub getEndpoint {
    my $self = shift;

    return $self->{api}->{config}->{$self->{name}}->{url};
}

sub DESTROY {
}

1;
