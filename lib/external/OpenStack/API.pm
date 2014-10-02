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
use OpenStack::Service;
use General;
use Kanopya::Exceptions;

use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("");

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'user', 'password', 'tenant_name', 'keystone_url' ]);

    my $self = {};
    bless $self , $class;

    my $config = {
        verify_ssl => 0,
        identity => {
            url => 'http://' . $args{keystone_url} . ':5000/v2.0'
        },
    };

    my $credentials = {
        auth => {
            passwordCredentials => {
                username => $args{user},
                password => $args{password},
            },
            tenantName => $args{tenant_name},
        }
    };

    $self->{config} = $config;
    $log->debug('Openstack::API config ' . (Dumper $self->{config}));

    $self->_login(credentials => $credentials);

    return $self;
}

my $api_version = {
    network => 'v2.0',
    image => 'v2.0',
    metering => 'v2',
};

sub _login {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ 'credentials' ]);

    my $response = $self->identity->tokens->post(content => $args{credentials});

    $log->debug('Service Catalog ' . Dumper($response->{access}->{serviceCatalog}));

    if( ! exists $response->{access}->{serviceCatalog} ||
        ! keys $response->{access}->{serviceCatalog} ) {
        throw Kanopya::Exception::Execution::API(
                  error => 'Openstack API call returns no service catalog'
	          )
    }

    for my $service (@{$response->{access}->{serviceCatalog}}) {
        my $name = $service->{type};

        $self->{config}->{$name}->{url} = $service->{endpoints}->[0]->{publicURL};

        if (! ($self->{config}->{$name}->{url} =~ /^http:\/\/.*\/v\d(\.\d)?(\/.*)?$/)) {
            $self->{config}->{$name}->{url} .= ((defined $api_version->{$name}) ? '/' . $api_version->{$name}
                                                                                : '/v1');
        }

        $self->{config}->{$name}->{adminURL} = $service->{endpoints}->[0]->{adminURL};

        if ($name eq 'identity') {
            my @endpoint_ids = map {$_->{id}} @{$service->{endpoints}};
            $self->{config}->{$name}->{endpoint_ids} = \@endpoint_ids;
        }
        $log->debug('Openstack::API login. Service name ' . $name . ' URL returned : '. $self->{config}->{$name}->{url});
    }

    $self->{token} = $response->{access}->{token}->{id};
    $self->{tenant} = $response->{access}->{token}->{tenant}->{id};

    # TODO process token expiration date (2013-01-25T16:21:38Z) => date_format()
    $self->{token_expiration} = $response->{access}->{token}->{expires};
}

sub logout {
}

sub AUTOLOAD {
    my ($self, %args) = @_;

    my @autoload = split(/::/, $AUTOLOAD);
    my $service = $autoload[-1];

    return OpenStack::Service->new(name => $service,
                                   api  => $self);
}

sub DESTROY {
}

sub faults {
    my ($self, %args) = @_;
    return ('badRequest', 'itemNotFound', 'unauthorized', 'forbidden',
            'badMethod', 'overLimit', 'badMediaType', 'unprocessableEntity',
            'instanceFault', 'notImplemented');
}


sub handleOutput {
    my ($self, %args) = @_;
    # sometime api call return nothing (e.g. delete)
    if (! defined $args{output}) {
        return;
    }

    for my $f (OpenStack::API->faults) {
        if (defined $args{output}->{$f}) {
            die($args{output}->{$f}->{message});
        }
    }

    return $args{output};
}
1;
