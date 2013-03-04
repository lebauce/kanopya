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

package OpenStack::API;

use OpenStack::Object;
use General;
use Kanopya::Exceptions;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'credentials', 'config' ]);

    my $self = {};
    bless $self , $class;

    $self->{config} = $args{config};

    # $self->login(); (saving credentials in object instance ?
    $self->login(credentials => $args{credentials});

    return $self;
}

sub login {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'credentials' ]);

    my $response = $self->tokens->post(target => 'identity', content => $args{credentials});

    # TODO serviceCatalog
    $self->{token} = $response->{access}->{token}->{id};

    $self->{tenant_id} = $self->tenants->get(target => 'identity')->{tenants}[0]->{id};

    # TODO process token expiration date (2013-01-25T16:21:38Z) => date_format()
    $self->{token_expiration} = $response->{access}->{token}->{expires};
}

sub logout {
}

# First AUTOLOAD() doesn't include args, they will be transmitted to OsObject.AUTOLOAD()
sub AUTOLOAD {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, optional => {'id' => undef});

    my @autoload = split(/::/, $AUTOLOAD);
    my $method = $autoload[-1];

    my $object = {
        path                => $method,
        config              => $self->{config},
        token               => $self->{token} || undef,
        token_expiration    => $self->{token_expiration} || undef,
    };
    # $args{id} is used to avoid methods starting with digit
    # images(id => '022efa') <---> images/022efa
    if ( defined $args{id} ) {
        $object->{path} = $method . '/' . $args{id};
    }
    else {
        $object->{path} = $method;
    }
    bless $object, 'OpenStack::Object';

    return $object;
}

# $os_api->tenant(id => '2abdf3')->servers->detail <---> 2abdf3/servers/detail
# to avoid method starting with digit
sub tenant {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'id' ]);

    my $object = {
        path    => $args{id},
        config  => $self->{config},
        token   => $self->{token} || undef,
        token_expiration    => $self->{token_expiration} || undef,
    };
    bless $object, 'OpenStack::Object';

    return $object;
}

sub DESTROY {
}

1;
