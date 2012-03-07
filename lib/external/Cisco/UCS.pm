package Cisco::UCS;

use warnings;
use strict;

use LWP;
use XML::Simple;
use Carp qw(croak carp);
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA               	= qw(Exporter);
our $VERSION		= '0.031';

my $debug_xmlrpc = 0;

=head1 NAME

Cisco::UCS - A Perl interface to the Cisco UCS XML API

=head1 SYNOPSIS

	use Cisco::UCS;

	my $ucs = new Cisco::UCS ( 	cluster		=> $cluster, 
					port		=> $port,
					proto		=> $proto,
					username	=> $username,
					passwd		=> $password
				);

	$ucs->login();

	@errors	= $ucs->get_errors(severity=>"critical",ack="no");

	foreach my $error_id (@errors) {
		my %this_error = $ucs->get_error_id($error_id);
		print "Error ID: $error_id.  Severity: $this_error{severity}.  Description: $this_error{descr}\n";
	}

	$ucs->logout();

=head1 DESCRIPTION

This package provides an abstracted interface to the Cisco UCS Manager XML API and Cisco UCS Management Information Model.

The Cisco UCS Manager (UCSM) is an embedded software agent providing access to the hardware and configuration management 
features of attached Cisco UCS hardware.  The Management Information Model for the UCSM is organised into a structured 
heirachy of both physical and virtual objects.  Accessing objects within the heirachy is done through a number of high
level calls to heirachy search and traversal methods.

The primary aim of this package is to provide a simplified and abstract interface to this management heirachy.

Most methods in this package return an anonymous hash, array, or array of anonymous hashes, representing the requested
object.  Unfortunately, this means that the documentation on return types and specific values may seem a little lacking.

=head2 METHODS

=head3 new

	my $ucs = new Cisco::UCS ( 	cluster		=> $cluster, 
					port		=> $port,
					proto		=> $proto,
					username	=> $username,
					passwd		=> $passwd
				);

Constructor method.  Creates a new Cisco::UCS object representing a connection to the Cisco UCSM XML API.  

Required parameters are:

=over 3

=item cluster

The common name of the target cluster.  This name should be resolvable on the host from which the script is run.

=item port

The port on which to connect to the UCSM XML API on the target cluster.  This value must be 80 or 443.

=item proto

The protocol with which to connect to the UCSM XML API on the target cluster.  This value must be one of either
'http' or 'https' and should be dictated by the value specified for the B<port> attribute.

=item username

The username to use for the connection.  This username needs to have the correct RBAC role for the operations that
one intends to perform.

=item passwd

The plaintext password of the username specified for the B<username> attribute for the connection.

=back

=head3 login

	$ucs->login;
	print "Authentication token is $ucs->{cookie}\n";

Creates a connection to the XML API interface of a USCM management instance.  If sucessful, the attributes of the 
UCSM management instance are inherited by the object.  Most important of these parameters is 'cookie' representing the 
authetication token that uniquely identifies the connection and which is subsequently passed transparently on all 
further communications.

The default time-out value for a token is 10 minutes, therefore if you intend to create a long-running session you
should periodicalily call refresh.

=head3 refresh

	$ucs->refresh;

Resets the expiry time limit of the existing authentication token to the default timeout period of 10m.  Usually not necessary
for short-lived connections.

=head3 logout

	$ucs->logout;

Expires the current authentication token.  This method should always be called on completion of a script to expire the authentication
token and free the current session for use by others.  The UCS XML API has a maximum number of available connections, and a maximum 
number of sessions per user.  In order to ensure that the session remain available (especially if using common credentials), you should 
always call this method on completion of a script, as an argument to die, or in any eval where a script may fail and exit before logging out;

=cut

sub new {
        @_ == 11 or croak 'Not enough arguments for constructor';
        my ($class, %args) = @_;
	my $self = {};
        defined $args{cluster}  ? $self->{cluster} 	= $args{cluster}	: croak 'cluster not defined';
        defined $args{port}     ? $self->{port} 	= $args{port}		: croak 'port not defined';
        defined $args{proto}	? $self->{proto} 	= $args{proto}		: croak 'proto not defined';
        defined $args{username} ? $self->{username}	= $args{username}	: croak 'username not defined';
        defined $args{passwd}	? $self->{passwd} 	= $args{passwd}		: croak 'passwd not defined';
        bless $self, $class;
        return $self;
}

sub login {
	my $self = shift;

	undef $self->{error};

	$self->{ua}	= LWP::UserAgent->new();
	$self->{uri}	= $self->{proto}. '://' .$self->{cluster}. ':' .$self->{port}. '/nuova';
	$self->{req}	= HTTP::Request->new(POST => $self->{uri});
	$self->{req}->content_type('application/x-www-form-urlencoded');
	$self->{req}->content('<aaaLogin inName="'. $self->{username} .'" inPassword="'. $self->{passwd} .'"/>');
	
	my $res	= $self->{ua}->request($self->{req});

	unless ($res->is_success()) {
        $self->{error}	= 'Login failure: '.$res->status_line();
		return
	}

	$self->{parser}	= XML::Simple->new();
	my $xml         = $self->{parser}->XMLin($res->content());

	if(defined $xml->{'errorCode'}) {
		$self->{error}	= 'Login failure: '. (defined $xml->{'errorDescr'} ? $xml->{'errorDescr'} : 'Unspecified error');
		return 
	}

	$self->{cookie}	= $xml->{'outCookie'};

	return 1
}

sub refresh {
	my $self = shift;
	
	undef $self->{error};

	$self->{req}->content('<aaaRefresh inName="'. $self->{username} .'" inPassword="'. $self->{passwd} .'" inCookie="' . $self->{cookie} . '"/>');
	my $res	= $self->{ua}->request($self->{req});

	unless ($res->is_success()) {
		$self->{error}	= 'Refresh failed: ' . $res->status_line();
		return
	}

	my $xml	= $self->{parser}->XMLin($res->content());

	if (defined $xml->{'errorCode'}) {
		$self->{error}	= 'Refresh failure: '. (defined $xml->{'errorDescr'} ? $xml->{'errorDescr'} : 'Unspecified error');
		return
	}

	$self->{cookie}	= $xml->{'outCookie'};

	return 1;
}

sub keepalive {
	my $self = shift;
	
	undef $self->{error};

	$self->{req}->content('<aaaKeepAlive cookie="' . $self->{cookie} . '"/>');
	my $res	= $self->{ua}->request($self->{req});

	unless ($res->is_success()) {
		$self->{error}	= 'Keep alive failed: ' . $res->status_line();
		return
	}

	my $xml	= $self->{parser}->XMLin($res->content());

	if (defined $xml->{'errorCode'}) {
		$self->{error}	= 'Keep alive failure: '. (defined $xml->{'errorDescr'} ? $xml->{'errorDescr'} : 'Unspecified error');
		return
	}

	return 1;
}

sub logout {
	my $self = shift;

	return unless defined $self->{cookie};

	undef $self->{error};

	$self->_ucsm_request('<aaaLogout inCookie="'. $self->{cookie} .'" />') or return;

	return 1;
}

sub _ucsm_request {
	my ($self, $content, $class_id)	= @_;

	undef $self->{error};

	if ($debug_xmlrpc) {
		print "Request: $content\n";
	}

    $self->{req}->content($content);
	my $res	= $self->{ua}->request($self->{req});

	unless ($res->is_success()) {
		$self->{error}	= $res->status_line();
		return
	}

	my $xml;

	if ($debug_xmlrpc) {
		print "Response: " . $res->content() . "\n";
	}

    if ($class_id) {
		$xml	= $self->{parser}->XMLin($res->content(), KeyAttr => $class_id);
	}
	else {
		$xml	= $self->{parser}->XMLin($res->content);
	}

	if (defined $xml->{errorCode}) {
		$self->{error}	= (defined $xml->{'errorDescr'} ? $xml->{'errorDescr'} : 'Unspecified error');
		return
	}
	
	return $xml
}

=head3 get_error_id

	my %error = $ucs->get_error_id($id);

	while (my($key,$value) = each %error) {
		print "$key:\t$value\n";
	}
	
Returns a hash containing the UCSM event detail for the given error id.  This method takes a single argument;
the UCSM error_id of the desired error.

See B<get_errors> for an example of how to obtain error_id values.

=cut

sub get_error_id {
	my ($self, $error_id)	= @_;

	return unless $self->_has_cookie;
	
	unless ($error_id =~ /[0-9]{1,9}/) {
		$self->{error}	= 'Error ID out of range (0-999999999)';
		return 
	}

	my $xml		= $self->_ucsm_request('<configResolveClass inHierarchical="false" cookie="' . $self->{cookie} . '" classId="faultInst" />') or return;

	my %error 	= %{$xml->{outConfigs}->{faultInst}->{$error_id}};

	return %error;
}

=head3 get_errors

	my @errors 	= $ucs->get_errors;
	my %error	= $ucs->get_error_id($errors[0]);
	print "Error $id: $error->{description}\n";

Returns an array of UCSM event ID's.  The full event description of the returned event ID's can be retrieved by passing the ID to get_error_id (see above).

=cut

sub get_errors {
	my ($self, %args)	= @_;

	$self->_check_args or return;
	undef $self->{error};

	my %severity	= (	
				critical	=> 1,
				major		=> 1,
				minor		=> 1,
				warning		=> 1,
				info		=> 1,
				condition	=> 1,
				cleared		=> 1,
				flapping	=> 1,
				soaking		=> 1
			);

	if (defined $args{severity} and !(defined $severity{$args{severity}})) {
		$self->{error}	= 'Unknown severity type specified: ';
		return
	}

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');
	$args{ack} 		= (defined $args{ack} ? _isYesNo($args{ack},'ack') : 'no');
	my $content;

	if (defined $args{severity}) {
		$content	= '<configResolveClass inHierarchical="' . $args{inHierarchical} . '" cookie="' . $self->{cookie} . '" classId="faultInst" >' . 
						'<inFilter>' .
							'<eq class="faultInst" property="severity" value="' . $args{severity} . '" />' . 
						'</inFilter>' . 
					'</configResolveClass>';
	}
	else {
		$content	= '<configResolveClass inHierarchical="' . $args{inHierarchical} . '" cookie="' . $self->{cookie} . '" classId="faultInst" />';
	}

	my $xml			= $self->_ucsm_request($content) or return;
	my @faults 		= keys %{$xml->{outConfigs}->{faultInst}};

	return @faults;
}

sub _has_cookie {
	my $self = shift;

	unless (defined $self->{cookie}) {
		$self->{error}	= 'No authentication token found';
		return
	}

	return 1
}

sub _isInHierarchical {
	my $inHierarchical	= lc shift;

	unless ($inHierarchical =~ /true|false|0|1/) {
		return 'false'
	}

	if ($inHierarchical =~ /^true|false$/) {
        return ($inHierarchical eq "true") ? "true" : "false"; 
    }

	return ($inHierarchical == 0 ? 'false' : 'true');
}

sub _isYesNo {
	my ($val, $var)	= @_;
	$var = lc $val;

	unless($val =~ /yes|no|0|1/) {
		return 'false'
	}

	return if ($val =~ /^false|yes$/);

	return ($val == 0 ? 'false' : 'yes');
}

sub _createFilter {
	my ($self, %args)	= @_;

	unless (defined $args{classId}) {
		$self->{error}	= 'No classId specified';
		return
	}

	my $filter	= '<inFilter><and>';

	while (my($property,$value) = each %args) {
		next if ($property eq 'inHierarchical' or $property eq 'classId');
		$filter	.= '<eq class="' . $args{classId} . '" property="' . $property . '" value="' . $value . '" />';
	}

	$filter		.= '</and></inFilter>';

	return $filter;
}

sub _check_args {
        my $self        = shift;
	
	$self->_has_cookie() or return;
	undef $self->{error};
#        defined $self->{ucs}->{cluster}	or	croak 'cluster not defined';
#        defined $self->{ucs}->{port}    or	croak 'port not defined';
#        defined $self->{ucs}->{proto}   or	croak 'proto not defined';
#        defined $self->{ucs}->{cookie}  or	croak 'cookie not defined';
#        defined $self->{ucs}->{dn}      or	croak 'dn not defined';
#        defined $self->{ucs}->{parser}  or	croak 'parser not defined';
#        defined $self->{ucs}->{ua}      or	croak 'ua not defined';
#        defined $self->{ucs}->{req}     or	croak 'req not defined';
        return 1;
}

=head3 resolve_class

This method is used to retrieve objects from the UCSM management heirachy by resolving the classId for specific
object types.  This method reflects one of the base methods provided by the UCS XML API for resolution of objects.
The method returns an XML::Simple parsed object from the UCSM containing the response.

Unless you have read the UCS XML API Guide and are certain that you know what you want to do, you shouldn't need
to alter this method.

=cut

sub resolve_class {
	my ($self,%args)= @_;

	$self->_check_args() or return;
	
	unless (defined $args{classId}) {
		$self->{error}	= 'No classId specified';
		return
	}

	$args{inHierarchical} = (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml	= $self->_ucsm_request('<configResolveClass inHierarchical="' . $args{inHierarchical} . 
						'" cookie="' . $self->{cookie} . '" classId="' . $args{classId} . '" />', 'classId') or return;

	return $xml
}	

=head3 resolve_classes

This method is used to retrieve objects from the UCSM management heirachy by resolving several classIds for specific
object types.  This method reflects one of the base methods provided by the UCS XML API for resolution of objects.
The method returns an XML::Simple object from the UCSM containing the parsed response.

Unless you have read the UCS XML API Guide and are certain that you know what you want to do, you shouldn't need
to alter this method.

=cut

sub resolve_classes {
	my ($self,%args)= @_;

	$self->_check_args() or return;

	unless (defined $args{classId}) {
		$self->{error}	= 'No classID specified';
		return
	}

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml	= $self->_ucsm_request('<configResolveClasses inHierarchical="' . $args{inHierarchical} . '" cookie="' . $self->{cookie} . '">' .
				'<inIds><Id value="' . $args{classId} . '" /></inIds></configResolveClasses>', 'classId') or return;

	return $xml
}	

=head3 resolve_dn

	my $blade = $ucs->resolve_dn( dn => 'sys/chassis-1/blade-2');

This method is used to retrieve objects from the UCSM management heirachy by resolving a specific distinguished name (dn)
for a managed object.  This method reflects one of the base methods provided by the UCS XML API for resolution of objects.
The method returns an XML::Simple parsed object from the UCSM containing the response.

The method accepts a single key/value pair, with the value being the distinguished name of the object.  If not known, the dn 
can be usually be retrieved by first using one of the other methods to retrieve a list of all object types (i.e. get_blades)
and then enumerating the results to extract the dn from the desired object.

	my @blades = $ucs->get_blades;i

	foreach my $blade in (@blades) {
		print "Dn is $blade->{dn}\n";
	}

Unless you have read the UCS XML API Guide and are certain that you know what you want to do, you shouldn't need
to alter this method.

=cut

sub resolve_dn {
	my ($self,%args)= @_;

	$self->_check_args() or return;

	unless (defined $args{dn}) {
		$self->{error}	= 'No dn specified';
		return
	}

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml	= $self->_ucsm_request('<configResolveDn dn="' . $args{dn} . '" inHierarchical="' . $args{inHierarchical} . '" cookie="' . $self->{cookie} . '" />') or return;

	return $xml;
}

=head3 resolve_children

	use Data::Dumper;

	my $children = $ucs->resolve_children(dn => 'sys');
	print Dumper($children);

This method is used to resolve all child objects for a given distinguished named (dn) object in the UCSM management 
heirachy.  This method reflects one of the base methods provided by the UCS XML API for resolution of objects.
The method returns an XML::Simple parsed object from the UCSM containing the response.

In combination with Data::Dumper this is an extremely useful method for further development by enumerating the child
objects of the specified dn.  Note however, that the response returned from UCSM may not always accurately reflect
all elements due to folding.

Unless you have read the UCS XML API Guide and are certain that you know what you want to do, you shouldn't need
to alter this method.

=cut

sub resolve_children {
	my ($self,%args)= @_;

	$self->_check_args() or return;

	unless (defined $args{dn}) {
		$self->{error}	= 'No dn specified';
		return
	}

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml	= $self->_ucsm_request('<configResolveChildren inHierarchical="' . $args{inHierarchical} . '" cookie="' . $self->{cookie} .
				'" inDn="' . $args{dn} . '"></configResolveChildren>') or return;

	return $xml
}	

=head3 resolve_class_filter

	my $associated_servers = $ucs->resolve_class_filter(	classId		=> 'computeBlade',
								association	=> 'associatied' 	);

This method is used to retrieve objects from the UCSM management heirachy by resolving the classId for specific
object types matching a specified filter composed of any number of key/value pairs that correlate to object attributes.

This method is very similar to the <B>resolve_class method, however a filter can be specified to restrict the objects
returned to thse having certain characteristics.  This method is largely exploited by subclasses to return specific
object types.

The filter is to be specified as any number of name/value pairs in addition to the classId parameter.

=cut

sub resolve_class_filter {
	my($self,%args)	= @_;

	$self->_check_args() or return;

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $filter	= $self->_createFilter(%args) or return;

	my $xml		= $self->_ucsm_request('<configResolveClass classId="' . $args{classId} . '" inHierarchical="' . $args{inHierarchical} . '" cookie="' . $self->{cookie} . '">' .
				$filter . '</configResolveClass>', 'classId') or return;

	return $xml
}

sub resolve_templates {
	my($self,%args)	= @_;

	$self->_check_args() or return;

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml		= $self->_ucsm_request('<lsResolveTemplates ' .
                  'inHierarchical="yes" ' . # $args{inHierarchical} .
                  'cookie="' . $self->{cookie} . '" ' .
                  # 'inType="initial-template" ' .
                  'inType="updating-template" ' .
                  # 'inExcludeIfBound="false" ' .
                  'dn="' . $args{dn} . '"' .
                  '>' .
				  '</lsResolveTemplates>', 'classId') or return;

	return $xml
}

=head3 get_cluster_status

	my $status = $ucs->get_cluster_status;

This method returns an anonymous hash representing a brief overall cluster status.  In the standard configuration
of a HA pair of Fabric Interconnects, this status is representative of the cluster as a single managed entity.

=cut

sub get_cluster_status {
	my $self= shift;

	$self->_check_args() or return;

	my $xml	= $self->resolve_dn(dn => 'sys') or return;

	return (defined $xml->{outConfig}->{topSystem} ? $xml->{outConfig}->{topSystem} : undef)
}

=head3 get_mgmt_entities

	my @mgmt_entities = $ucs->get_mgmt_entities;

	foreach $entity (@mgmt_entities) {
		print "Management entity $entity->{id} is the $entity->{role} entity\n";
	}

Returns an anonymous array containing information on the UCSM management entity objects.  The management entity is representitive 
of an instance of the UCSM agent running on a supported hardware platform (Fabric Interconnects).

Note that there is a difference between the Fabric Interconnect as a hardware platform that provides the physical hardware platform
for hosting UCSM management entity instance and providing the cluster capabilties and the management entity as a logical construct.

=cut

sub get_mgmt_entities {
        my $self= shift;

	$self->_check_args() or return;

	my $xml	= $self->resolve_class(classId  => 'mgmtEntity') or return;

	return (defined $xml->{outConfigs}->{mgmtEntity} ? @{$xml->{outConfigs}->{mgmtEntity}} : undef)
}


=head3 get_primary_mgmt_entity

	my $primary = $ucs->get_primary_mgmt_entity;
	print "Management entity $entity->{id} is primary\n";

Returns an anonymous hash contaiing information on the primary UCSM management entity object.  
This is the active managing instance of UCSM in the target cluster.

=cut


sub get_primary_mgmt_entity {
	my $self	= shift;

	$self->_check_args() or return;

	my $xml		= $self->resolve_class_filter(classId => 'mgmtEntity', leadership => 'primary') or return;

	return (defined $xml->{outConfigs}->{mgmtEntity} ? $xml->{outConfigs}->{mgmtEntity} : undef)
}

=head3 get_subordinate_mgmt_entity

	print 'Management entity ', $ucs->get_subordinate_mgmt_entity->{id}, ' is the subordinate management entity in cluster ',$ucs->{cluster},"\n";

Returns an anonymous hash containing information on the subordinate UCSM management entity object.  

=cut

sub get_subordinate_mgmt_entity {
	my $self= shift;

	$self->_check_args() or return;

	my $xml	= $self->resolve_class_filter(classId => 'mgmtEntity', leadership => 'subordinate') or return;

	return (defined $xml->{outConfigs}->{mgmtEntity} ? $xml->{outConfigs}->{mgmtEntity} : undef);
}

=head3 get_service_profile

Returns an anonymous hash containing information on the requested service profile object.

=cut

sub get_service_profile {
	my ($self,%args) = @_; 

	$self->_check_args() or return;

	unless (defined $args{dn}) {
		$self->{error}	= 'No dn specified';
		return
	}

	$args{inHierarchical}	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml	= $self->resolve_dn($self,%args) or return;
        
	return (defined $xml->{outConfig}->{lsServer} ? $xml->{outConfig}->{lsServer} : undef)
}

=head3 get_service_profiles

	my @service_profiles = $ucs->get_service_profiles;

	foreach my $service_profile (@service_profiles) {
		print "Service Profile: $service_profile->{name}\n";
	}

Returns an array of anonymous hashs representing configured service profile objects.  

=cut


sub get_service_profiles {
	my $self = shift;

	$self->_check_args() or return [];

	my $xml	= $self->resolve_class_filter(classId => 'lsServer', type => 'instance') or return [];

	return (defined $xml->{outConfigs}->{lsServer} ? @{$xml->{outConfigs}->{lsServer}} : [])
}

=head3 get_service_profile_templates

	my @templates = $ucs->get_service_profile_templates;

	foreach my $template (@templates) {
		print "Service Profile Template: $template->{name}\n";
	}

Returns an array of anonymous hashs representing configured service profile templates objects.  

=cut


sub get_service_profile_templates {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

	my $xml	= $self->resolve_templates(inHierarchical => "true",
	                                   dn => $args{dn}) or return;

	my @templates = ();

	if (defined $xml->{outConfigs}->{pair}) {
		my @pairs = @{$xml->{outConfigs}->{pair}};
		for my $pair (@pairs) {
			push @templates, $pair->{lsServer};
		}
	}

	return @templates;
}

sub instantiate_service_profile {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

	my $xml	= $self->_ucsm_request('<lsInstantiateTemplate '.
	          'cookie="' . $self->{cookie} . '" ' .
	          'dn="' . $args{dn} . '" ' .
	          'inTargetOrg="' . $args{targetOrg} . '" ' .
	          'inServerName="' . $args{name} . '" ' .
	          'inHierarchical="yes"' .
	          '>' .
	          '</lsInstantiateTemplate>', 'classId') or return;
}

sub set_service_profile_power_state {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

	my $xml = $self->_ucsm_request('<configConfMo cookie="' . $self->{cookie} . '" inHierarchical="false">' .
	                               '<inConfig>' .
                                   '<lsServer ' .
                                   'dn="' . $args{dn} . '" >' .
	                               '<lsPower childAction="deleteNonPresent"  rn="power" state="' . $args{state} . '" /> ' .
                                   '</lsServer>' .
	                               '</inConfig>' .
                                   '</configConfMo>');
}

sub start_service_profile {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

	$self->set_service_profile_power_state(%args,
                                           state => "up");
}

sub reboot_service_profile {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

	$self->set_service_profile_power_state(%args,
                                           state => "cycle-wait");
}

sub shutdown_service_profile {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

	$self->set_service_profile_power_state(%args,
                                           state => "soft-shut-down");
}

sub instantiate_template {
	my ($self, %args) = @_; 

	$self->_check_args() or return;

    my $param = "";
	if (defined $args{count} and
        defined $args{prefix}) {
		$param = "inNumberOf=$args{count} " .
                 "inServerNamePrefixOrEmpty=$args{prefix} ";
    }

	my $xml	= $self->_ucsm_request('<lsInstantiateTemplate '.
	          'cookie="' . $self->{cookie} . '" ' .
	          'dn="' . $args{dn} . '" ' .
	          'inTargetOrg="' . $args{targetOrg} . '" ' .
	          'inServerName="' . $args{name} . '" ' .
	          'inHierarchical="yes"' .
              $param .
	          '>' .
	          '</lsInstantiateTemplate>', 'classId') or return;
}

=head3 get_interconnects

	my @interconnects = $ucs->get_interconnects;

	foreach my $ic (@interconnects) {
		print "Interconnect $ic HA status is $ic->{ha_ready}\n";
	}

Returns an array of anonymous hashs representing UCS Fabric Interconnect objects.  

=cut

sub get_interconnects {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	$args{classId}		= 'networkElement';

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml 		= resolve_classes($self,%args);

	undef $args{classID};

	return (defined $xml->{outConfigs}->{networkElement} ? @{$xml->{outConfigs}->{networkElement}} : undef)
}

=head3 get_interconnect

	my $interconnect = $ucs->get_interconnect(dn => 'sys/switch-A');

	or

	my $interconnect = $ucs->get_interconnect(id => 'A');

Returns an anonymous hash containing information on the specified UCS Fabric Interconnect object.  
The method accepts either the distinguished name of the desired Interconnect, or the ID of the 
Fabric Interconnect in the target cluster.

=cut

sub get_interconnect {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	unless (defined $args{dn} or $args{id} or $args{serial}) {
		$self->{error}	= 'No dn or id or serial defined';
		return
	}

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	my $xml;

	if ($args{dn}) {
		$xml		= $self->resolve_dn(%args);
	}
	else { 
		$args{classId}	= 'networkElement';
		$xml		= $self->resolve_class_filter(%args);
		undef $args{classId};
	}

	return (defined $xml->{outConfig}->{networkElement} ? $xml->{outConfig}->{networkElement} : undef)
}

=head3 get_fexs

	my @fexs = $ucs->get_fexs;
	print "Fabric Extender - thermal $fex[0]->{thermal} - temperature $fex[0]->{temp}\n";

Returns an array of anonymous hashes, each containing information on a UCS Fabric Extender object
identified within the cluster.

=cut

sub get_fexs {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	$self->{classId}	= 'equipmentIOCard';
	my $xml;

	if (defined $args{chassisId}) {
		$xml	= $self->resolve_class_filter(%args)
	}
	else {
		$xml	= $self->resolve_class()
	}

	undef $self->{classId};
	return (defined $xml->{outConfigs}->{equipmentIOCard} ? @{$xml->{outConfigs}->{equipmentIOCard}} : undef)
}

=head3 get_fex

	my $fex = $ucs->get_fex(dn => 'sys/chassis-1/slot-1');

	or

	my $fex = $ucs->get_fex(chassisId => 1,	id => 1);

Returns an anonymous hash containing information on a UCS Fabric Extender object.  
The Fabric Extender (FEX) may be given either by distinguished name (dn) or by physical locality of the residing chassis and slot.

=cut

sub get_fex {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	unless ($args{dn} or $args{serial} or ($args{chassisId} and $args{id})) {
		$self->{error}	= 'No dn or serial or chassis ID and FEX ID specified';
		return
	}

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');
	my $xml;

	if (defined $args{dn}) {
		$xml		= $self->resolve_dn(%args)
	}
	else {
		$self->{classId}= 'equipmentIOCard';
		$xml		= $self->resolve_class_filter(%args);
		undef $self->{classId};
	}
	
	return (defined $xml->{outConfigs}->{equipmentIOCard} ? $xml->{outConfigs}->{equipmentIOCard} : undef)
}

=head3 get_blades

	my @blades = $ucs->get_blades();

	foreach my $blade (@blades) {
		print "Model: $blade->{model}\n";
	}

Returns an array of hashes each representative of a UCS server object.  The returned objects are identical
to those represented by the Cisco::UCS::Blade subclass.

=cut

sub get_blades {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');
	$args{classId}		= 'computeBlade';
	my $xml;
	
	if ($args{chassisId}) {
		$xml		= $self->resolve_class_filter(%args)
	}
	else {
		$xml		= $self->resolve_classes(%args)
	}

	undef $args{classId};

	return (defined $xml->{outConfigs}->{computeBlade} ? @{$xml->{outConfigs}->{computeBlade}} : undef)
}

=head3 get_blade

	my blade = $ucs->get_blade(dn => 'sys/chassis-1/blade-2'

	or

	my $blade = $ucs->get_blade(chassisId => 1, slotId => 2);

	or

	my $blade = $ucs->get_blade(serial => 'QJ547L9987');

	or

	my $blade = $ucs->get_blade(uuid => '0000-000000-000000');

Returns an anonymous hash representing a UCS server blade object.  The blade may be specified either by 
distinguished name (dn), by physical locality of chassis and slot id, by serial number or by uuid.

=cut

sub get_blade {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	unless ($args{dn} or $args{serial} or $args{uuid} or ($args{chassisId} and $args{slotId})) {
		$self->{error}	= 'No dn or serial or uuid or chassis ID and slot ID specified';
		return
	}

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');
	my $xml;

	if ($args{dn}) {
		$xml		= $self->resolve_dn($self,%args);
	}
	else {
		$args{classId} 	= 'computeBlade';
		$xml 		= $self->resolve_class_filter($self,%args);
		undef $args{classId}
	}
	
	return (defined $args{dn} ? $xml->{outConfig}->{computeBlade} : $xml->{outConfigs}->{computeBlade})
}

=head3 get_chassiss
	
	my @chassis = $ucs->get_chassiss();

	foreach my $chassis (@chassis) {
		print "Chassis $chassis->{id} serial number: $chassis->{serial}\n";
	}

Returns an array of hashes with each hash containing information on a single chassis within the system.

Note that this method is named get_chassiss (spelt with two sets of double-s's) as there exists no English language collective plural for
the word chassis.

=cut

sub get_chassiss {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	unless ($args{dn} or $args{serial} or $args{uuid} or ($args{chassisId} and $args{slotId})) {
		$self->{error}	= 'No dn or serial or uuid or chassis ID and slot ID specified';
		return
	}

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');

	$args{classId}		= 'equipmentChassis';
	my $xml 		= $self->resolve_classes($self,%args);
	undef $args{classID};

	return (defined $xml->{outConfigs}->{equipmentChassis} ? @{$xml->{outConfigs}->{equipmentChassis}} : undef)
}

=head3 get_chassis

	my $chassis = $ucs->get_chassis;
	print "Chassis serial number: $chassis->{serial}\n";
	my $chassis = new UCS::Chassis(dn => $chassis->{dn});

Returns a hash containing information about the requested chassis given the distinguished name (dn) 
of a chassis in the target cluster.  This method is typically used for the creation of a UCS::Chassis object.

=cut

sub get_chassis {
	my ($self,%args)	= @_;

	$self->_check_args() or return;

	unless ($args{dn} or $args{serial} or $args{id} or $args{uuid}) {
		$self->{error}	= 'No dn or serial or uuid or chassis ID and slot ID specified';
		return
	}

	$args{inHierarchical} 	= (defined $args{inHierarchical} ? _isInHierarchical($args{inHierarchical}) : 'false');
	my $xml;

	if ($args{dn}) {
		$xml		= $self->resolve_dn($self,%args);
	}
	else {
		$args{classId}	= 'equipmentChassis';
		$xml		= $self->resolve_class_filter($self,%args);
		undef $args{classId};
	}

	return (defined $args{dn} ? $xml->{outConfig}->{equipmentChassis} : $xml->{outConfigs}->{equipmentChassis})
}

=head3 get_psus

This method provides a method for child classes that returns all power supply units for a specific object type.  Arguably, this method
should not be in this class as the concept of a UCS object as an abstract 'type' does not physically or logically 'have' a PSU.  
The justification for having this method in the parent class is to reduce code duplication, but this is a candidate for removal as it is 
almost always overridden in subclasses.

=cut

sub get_psus {
        my ($self,$psu)	= @_; 

	$self->_check_args() or return;

        my $xml		= $self->resolve_children(dn => $self->{dn});
        $xml		= %{$xml->{outConfigs}->{equipmentPsu}};

	defined $psu and return $psu->{outConfigs}->{equipmentPsu}->{$psu};

	my @xml;

	while (my($key,$value) = each(%{$xml})) {
		push @xml, $value;
	}

	return @xml;
}

=head3 get_psu

This method provides a method for child classes that returns the power supply unit for a specific object type.  Arguably, this method
should not be in this class as a UCS object as an abstract type does not have a PSU.  The justification for having this method in the 
parent class is to reduce code duplication, but this is a candidate for removal as it is almost always overridden in sbclasses.

=cut

sub get_psu {
        my ($self,$psu)	= @_; 

        $self->_check_args or return;

	return $self->get_psus($psu);
}

=head3 full_state_backup

This method generates a new "full state" type backup for the target UCS cluster.  Internally, this method is implemented as a 
wrapper method around the private backup method.  Required parameters for this method:

=over 3

=item backup_proto 

The protocol to use for transfering the backup from the target UCS cluster to the backup host.  Must be one of: ftp, tftp, scp or sftp.

=item backup_host

The host to which the backup will be transferred.

=item backup_target

The fully qualified name of the file to which the backup is to be saved on the backup host.  This should include the full directory
path and the target filename.

=item backup_username

The username to be used for creation of the backup file on the backup host.  This username should have write/modify file system access to
the backup target location on the backup host using the protocol specified in the backup-proto attribute.

=item backup_passwd

The plaintext password of the user specified for the backup_username attribute.

=back

=cut

sub full_state_backup {
	my ($self,%args)= @_;

	$args{backup_type}= 'full-state';

	return ($self->_backup(%args));
}

=head3 all_config_backup

This method generates a new "all configuration" backup for the target UCS cluster.  Internally, this method is implemented as a
wrapper method around the private backup method.  For the required parameters for this method, please refer to the documentation of
the B<full_state_backup> method.

=cut

sub all_config_backup {
	my ($self,%args)= @_;

	$args{backup_type}= 'config-all';

	return ($self->_backup(%args));
}

=head3 system_config_backup

This method generates a new "system configuration" backup for the target UCS cluster.  Internally, this method is implemented as a
wrapper method around the private backup method.  For the required parameters for this method, please refer to the documentation of
the B<full_state_backup> method.

=cut

sub system_config_backup {
	my ($self,%args)= @_;

	$args{backup_type}= 'config-system';

	return ($self->_backup(%args));
}

=head3 logical_config_backup

This method generates a new "logical configuration" backup for the target UCS cluster.  Internally, this method is implemented as a
wrapper method around the private backup method.  For the required parameters for this method, please refer to the documentation of
the B<full_state_backup> method.

=cut

sub logical_config_backup {
	my ($self,%args)= @_;

	$args{backup_type}= 'config-logical';

	return ($self->_backup(%args));
}

sub _backup {
	my ($self,%args)= @_;

	unless (defined $args{backup_type} 	and
		defined $args{backup_proto}	and
		defined $args{backup_host}	and
		defined $args{backup_target}	and
		defined $args{backup_passwd}	and
		defined $args{backup_username} ) 
	{
		$self->{error} = 'Bad argument list';
		return
	}

	$args{admin_state}		= (defined $args{admin_state} ? $args{admin_state} : 'enabled');
	$args{preserve_pooled_values}	= (defined $args{preserve_pooled_values} ? $args{preserve_pooled_values} : 'yes');

	unless ($args{backup_type} =~ /(config-all|full-state|config-system|config-logical)/i) {
		$self->{error} = "Bad backup type ($args{backup_type})";
		return
	}

	unless ($args{backup_proto} =~ /^((t|s)?ftp)|(scp)$/i) {
		$self->{error} = "Bad backup proto' ($args{backup_proto})";
		return
	}

	my $address	= $self->get_cluster_status->{address};

	my $xml 	= $self->_ucsm_request('<configConfMos cookie="' . $self->{cookie} . '" inHierarchical="false"><inConfigs><pair key="sys">' .
				'<topSystem address="' . $address . '" dn="sys" name="' . $self->{cluster} . '">' .
				'<mgmtBackup adminState="' . $args{admin_state} . '" descr="" preservePooledValues="' . $args{preserve_pooled_values} .
				'" proto="' . $args{backup_proto} . '" pwd="' . $args{backup_passwd} . '" remoteFile="' . $args{backup_target} . 
				'" hostname="' . $args{backup_host} . '" dn="backup-' . $args{backup_host} . '" type="' . $args{backup_type} . '" ' .
				'user="' . $args{backup_username} . '"></mgmtBackup></topSystem></pair></inConfigs></configConfMos>'
			) or return;

	if (defined $xml->{'errorCode'}) {
		my $self->{error} = (defined $xml->{'errorDescr'} ? $xml->{'errorDescr'} : "Unspecified error");
		return
	}

	return 1;
}

=head1 TODO

Quite a lot; this package started out as a way to easily reduce the amount of copying and pasting I was doing but it grew quickly.
Note everything has been implemented nicely and this package barely scrapes the surface of the UCS API capabilities.

=over 3

=item *

The documentation could be cleaner and more thorough.  The module was written some time ago with only minor amounts of time and effort invested since.
There's still a vast oppotunity for improvement.

=item *

Better error detection and handling.  Liberal use of Carp::croak should ensure that we get some minimal diagnostics and die nicely, and if 
used according to instructions, things should generally work.  When they don't however, it would be nice to know why.

=item *

Detection of request and return type.  Most of the methods are fairly explanatory in what they return, however it would be nice to
make better use of wantarray to detect what the user wants and handle it accordingly.

=item *

Clean up of the UCS package to remove unused methods and improve the ones that we keep.  I'm still split on leaving some of the 
methods common to most object type (fans, psus) in the main package.

=back

=head1 AUTHOR

Luke Poskitt, C<< <luke.poskitt at gmail.com> >>

=cut

=head1 BUGS

Plenty, I'm sure.

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; 

