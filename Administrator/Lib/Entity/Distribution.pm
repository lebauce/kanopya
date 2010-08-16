package Entity::Distribution;

use strict;
use lib qw(/workspace/mcs/Administrator/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use base "Entity";
use Data::Dumper;

use Log::Log4perl "get_logger";
my $log = get_logger("administrator");

use constant ATTR_DEF => {
	distribution_name => {pattern => //, is_mandatory => 1, is_extended => 0},
	distribution_version => {pattern => //, is_mandatory => 1, is_extended => 0},
	distribution_desc => {pattern => //, is_mandatory => 1, is_extended => 0},
	etc_device_id => {pattern => //, is_mandatory => 1, is_extended => 0},
	root_device_id => {pattern => //, is_mandatory => 1, is_extended => 0}
};

=head new

=cut

sub new {
    my $class = shift;
    my %args = @_;

    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		throw Mcs::Exception::Internal::IncorrectParam(error => "Entity::Distribution->new need a data and rightschecker named argument!"); }

	my $ext_attrs = $args{ext_attrs};
	delete $args{ext_attrs};
    my $self = $class->SUPER::new( %args );
	$self->{_ext_attrs} = $ext_attrs;
	$self->{extension} = $self->extension();
    return $self;
}

=head getDevice 

get etc device attributes
named argument: type (can be 'etc' or 'root') 


=cut

sub getDevice {
	my $self = shift;
	my %args = @_;
	if (! exists $args{type} or ! defined $args{type}) { 
		throw Mcs::Exception::Internal::IncorrectParam(
			error => "Entity::Distribution->getDevice need a type named argument!"); 
	}
	my $device = {};
	#my $row = $self->{_dbix}->result
	
}



1;