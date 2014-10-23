#    Copyright © 2014 Hedera Technology SAS
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

package AWS::API;

use General;

use AWS::Signature4;
use HTTP::Request::Common ();
use LWP::UserAgent;
use TryCatch;
use URI;
use XML::LibXML;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod
=begin classdoc

@constructor

Create a new API object, for direct HTTP calls to AWS.

@param aws_account (Entity::Component::Virtualization::AwsAccount) 
Needs to be either a real AwsAccount object or 
a hashref with the keys 'aws_account_key', 'aws_secret_key' and 'region'.

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'aws_account' ]);

    $log->info(Data::Dumper->Dump([ $args{aws_account}->api_access_key, $args{aws_account}->api_secret_key ]));

    my $self = {
        # aws_account => $args{aws_account},  # not necessary for the moment
        region => $args{aws_account}->region,
        version => '2014-06-15',

        signer => AWS::Signature4->new(
            '-access_key' => $args{aws_account}->api_access_key,
            '-secret_key' => $args{aws_account}->api_secret_key
        ),
        user_agent => LWP::UserAgent->new()
    };
    bless $self, $class;

    return $self;
}



=pod
=begin classdoc

Return the right URL for the given purpose.

@param service (String) What service to reach: 'ec2', 'identity'...

@return The base URL as a String.

=end classdoc
=cut

sub _url {
    my ($self, $service) = @_;
    
    if ($service eq 'identity') {
        return 'https://iam.amazonaws.com'
    } else {
        return 'https://'.$service.'.'.$self->{region}.'.amazonaws.com';
    }
}


=pod
=begin classdoc

Execute a GET request to the AWS API.

@param action (String) The AWS action. For EC2, see http://docs.aws.amazon.com/AWSEC2/latest/APIReference/query-apis.html
@param service (String) "identity" for identity requests, undef or "ec2" for EC2 requests.
@param params (Arrayref) Key-value pairs to give as arguments in the request.
  You can break up Amazon's lists by specifying the key without the ".n" attachment and a listref as its value.

@return The response (XML string).

=end classdoc
=cut

sub get {
    my ($self, %args) = @_;    
    General::checkParams(
        args => \%args, 
        required => [ 'action' ],
        optional => { service => 'ec2', params => [] }
    );
    $log->debug("GET arguments: ".Data::Dumper->Dump([ \%args ]));
    my $params = $self->_flattenParams($args{params});
    
    my $uri = URI->new($self->_url($args{service}));
    $uri->query_form(
        Action => $args{action},
        Version => $self->{version},
        @$params
    );
    
    $log->debug("Signing GET: ".Data::Dumper->Dump([ $uri ]));
    my $signed_url = $self->{signer}->signed_url($uri);
    my $response = $self->{user_agent}->get($signed_url);
    
    if (! $response->is_success) {
        die("The request was not successful: ".Data::Dumper->Dump([ $response ]));
    }
    else { $log->debug("Request successful, response: ".Data::Dumper->Dump([$response])) }
    
    open my $fh, '<', $response->content_ref;
    my $xml = XML::LibXML->load_xml(IO => $fh);
    close $fh;
    
    return $xml;
}


=pod
=begin classdoc

Execute a GET request to the AWS API.
Takes direct parameters (no hash) !
Can be called as an instance or as a class method.

@param paramlist (Arrayref) Key-value pairs to give as arguments in the request.

@return The same paramlist, where arrayref "values" have been flattened into several key-value pairs.

=end classdoc
=cut

sub _flattenParams {
    my ($clob, $params) = @_;
    
    my @flat_params = ();
    if (ref($params) ne 'ARRAY') {
        die "AWS::API::_flattenParams must be called with an Arrayref";
    }
    
    my $params_length = scalar(@$params);
    if ($params_length % 2 == 1) {
        die "AWS::API::_flattenParams must be called with a key-value Arrayref (even number of items)";
    }
    
    my $i = 0;
    while ($i < $params_length) {
        my ($key, $value) = ($params->[$i], $params->[$i+1]);
        if (ref($value) eq 'ARRAY') {
            my $flat_count = 1;
            foreach my $flat_value (@$value) {
                push @flat_params, $key.".$flat_count", $flat_value;
                $flat_count++;
            }
        } else {
            push @flat_params, $key, $value;
        }
        $i += 2;
    }
    
    return \@flat_params;
}


sub findNodeInResponse {
    my ($self, %args) = @_;
    
}


=pod
=begin classdoc

Execute a POST request to the AWS API.

@param action (String) The AWS action. For EC2, see http://docs.aws.amazon.com/AWSEC2/latest/APIReference/query-apis.html
@param service (String) "identity" for identity requests, undef or "ec2" for EC2 requests.

@return The response.

=end classdoc
=cut

sub post {
    my ($self, %args) = @_;
    General::checkParams(
        args => \%args, 
        required => [ 'action' ],
        optional => { service => 'ec2' }
    );
    
    my $request = HTTP::Request::Common::POST(
        $self->_url($args{service}),
        [
            Action => $args{action},
            Version => $self->{version}   
        ]
    );
    
    $self->{signer}->sign($request);
    my $response = $self->{user_agent}->request($request);
    
    return $response;
}

=pod
=begin classdoc

Lazily load an XPathContext object with an "x" namespace prefix, so you can use it like this:

my @nodes = $api->xpc->find('//x:imagesSet/x:item', $xml_response);

@return A XML::LibXML::XPathContext instance with the "x" prefix.

=end classdoc
=cut

sub xpc {
    my ($self) = @_;
    unless (defined $self->{xpc}) {
        my $xpc = XML::LibXML::XPathContext->new;
        $xpc->registerNs('x', 'http://ec2.amazonaws.com/doc/2014-06-15/');
        $self->{xpc} = $xpc;    
    }
    return $self->{xpc};
}


=pod
=begin classdoc

Parse a XML response, look for errors.

@param xml The response.

@return The errors, as an arrayref of tuples {code, message}. Empty arrayref if all is OK.

=end classdoc
=cut

sub findErrors {
    my ($self, $xml) = @_;
    my $xpc = $self->xpc;
    my @errors = ();
    
    foreach my $error ($xpc->findnodes('//x:Response/x:Errors/x:Error', $xml)) {
        push @errors, {
            code    => $xpc->findvalue('x:Code', $error),
            message => $xpc->findvalue('x:Message', $error)
        };
    }
    return \@errors;
}


#
#
#
#my $api_version = {
#    network => 'v2.0',
#    image => 'v2.0',
#    metering => 'v2',
#};
#
#sub _login {
#    my ($self, %args) = @_;
#
#    General::checkParams(args => \%args, required => [ 'credentials' ]);
#
#    my $response = $self->identity->tokens->post(content => $args{credentials});
#
#    $log->debug('Service Catalog ' . Dumper($response->{access}->{serviceCatalog}));
#
#    if( ! exists $response->{access}->{serviceCatalog} ||
#        ! keys %{$response->{access}->{serviceCatalog}} ) {
#        throw Kanopya::Exception::Execution::API(
#                  error => 'Openstack API call returns no service catalog'
#	          )
#    }
#
#    for my $service (@{$response->{access}->{serviceCatalog}}) {
#        my $name = $service->{type};
#
#        $self->{config}->{$name}->{url} = $service->{endpoints}->[0]->{publicURL};
#
#        if (! ($self->{config}->{$name}->{url} =~ /^http:\/\/.*\/v\d(\.\d)?(\/.*)?$/)) {
#            $self->{config}->{$name}->{url} .= ((defined $api_version->{$name}) ? '/' . $api_version->{$name}
#                                                                                : '/v1');
#        }
#
#        $self->{config}->{$name}->{adminURL} = $service->{endpoints}->[0]->{adminURL};
#
#        $log->debug('Openstack::API login. Service name ' . $name . ' URL returned : '. $self->{config}->{$name}->{url});
#    }
#
#    $self->{token} = $response->{access}->{token}->{id};
#    $self->{tenant} = $response->{access}->{token}->{tenant}->{id};
#
#    # TODO process token expiration date (2013-01-25T16:21:38Z) => date_format()
#    $self->{token_expiration} = $response->{access}->{token}->{expires};
#}
#
#sub logout {
#}
#
#sub AUTOLOAD {
#    my ($self, %args) = @_;
#
#    my @autoload = split(/::/, $AUTOLOAD);
#    my $service = $autoload[-1];
#
#    return OpenStack::Service->new(name => $service,
#                                   api  => $self);
#}
#
#sub DESTROY {
#}
#
#sub faults {
#    my ($self, %args) = @_;
#    return ('badRequest', 'itemNotFound', 'unauthorized', 'forbidden',
#            'badMethod', 'overLimit', 'badMediaType', 'unprocessableEntity',
#            'instanceFault', 'notImplemented');
#}
#
#
#sub handleOutput {
#    my ($self, %args) = @_;
#    # sometime api call return nothing (e.g. delete)
#    if (! defined $args{output}) {
#        return;
#    }
#
#    for my $f (OpenStack::API->faults) {
#        if (defined $args{output}->{$f}) {
#            die($args{output}->{$f}->{message});
#        }
#    }
#
#    return $args{output};
#}

1;
