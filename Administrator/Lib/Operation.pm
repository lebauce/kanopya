package Operation;

use strict;
use warnings;
use lib qw(../../Common/Lib);
use Log::Log4perl "get_logger";

use McsExceptions;

my $log = get_logger("administrator");

# contructor 

=head2 new
	
	Class : Public
	
	Desc : This method instanciate Operation.
	
	Args :
		rightschecker : Rightschecker : Object use to check write and update entity_id
		data : DBIx class: object data
	Return : Entity::Operation, this class could not be instanciated !!
	
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})) { 
		throw Mcs::Exception::Internal(error => "Entity->new need a data and rightschecker named argument!"); }
    $log->warn("Data : $args{data} and $args{rightschecker}");
    
    my $self = {
    	_rightschecker => $args{rightschecker},
        _data => $args{data},
        _ext_params => {},
    };
    bless $self, $class;
    
    # getting groups where we find this entity (entity already exists)
	if($self->{_data}->in_storage) {
		$self->{_groups} = $self->getGroups;
	}
	$log->warn("new return $self");
    return $self;
}

=head2 delete
	
	Class : Public
	
	Desc : This method delete Entity::Operation and its parameters
	
=cut

sub delete {
	my $self = shift;

	my $params_rs = $self->{_data}->operation_parameters;
	$params_rs->delete;
	
	$self->SUPER::delete( );	
}

=head2 addParams
	
	Class : Public
	
	Desc : This method Add params to operation, operation has to be saved before 
	
	Args :
		params : hashref : Operation parameters
	
=cut

sub addParams {
	my $self = shift;
	my ($params) = @_;	
	my $data = $self->{_data};
	
	# create_related will automatically insert _data in db
	# we don't want this behaviour
	# TODO comprendre comment marche le new_related (et ensuite accéder aux related data, ajouter dans la base, cascade_update...)
	if ( ! $self->{_data}->in_storage ) {
		throw Mcs::Exception::Internal(error => "Error: Please save your Operation before call addParams");
	}
	
	foreach my $k (keys %$params) {
			$data->create_related( 'operation_parameters', { name => $k, value => $params->{$k} } );
	}
	return 0;
}

=head2 getParams
	
	Class : Public
	
	Desc : This method return hashref on operation params.
	
	Return : hashref : Operation parameters { p1 => v1, p2 => v2, ...}
	
=cut

sub getParams {
	my $self = shift;
	
	my %params = ();
	my $params_rs = $self->{_data}->operation_parameters;
#	my $params_rs = $self->getValue(name => "operation_parameters");
	
	while ( my $param = $params_rs->next ) {
		$params{ $param->name } = $param->value;
	}
	return \%params;
}

=head2 getUser
	
	Class : Public
	
	Desc : This method return user_id of operation owner
	
	Return : int : operation owner user_id
	
=cut

sub getUser {
	my $self = shift;
	return $self->getAttr(name => "user_id");
}

=head2 getParamValue
	
	Class : Public
	
	Desc : This method return value of a specific param 
	
	Args :
		param_name : String : Param search in operation
	
	Return : Param_value $ : value of searched param
=cut

sub getParamValue {
	my $self = shift;
	my %args = @_;

	if (! exists $args{param_name} or ! defined $args{param_name}) {
		throw Mcs::Exception::Internal(error => "Error: Please save your Operation before call addParams");
	}

	my $params_rs = $self->{_data}->operation_parameters;
	
	my $param = $params_rs->search( { name => $args{param_name} } )->next;
	return $param->value;
}

=head2 save

	Class : Public
	
	Desc : Save operation and its params
	args : 
		op : Entity::Operation::OperationType : 
			concrete Entity::Operation type (Real Operation type (AddMotherboard, MigrateNode, ...))

=cut

sub save{
	my $self = shift;
	my %args = @_;
	
	throw Mcs::Exception::Internal(error => "Try to save object not operation") if (
													(!exists $args{op})||
													(! $args{op}->isa('Entity::Operation')));

	my $newentity = $self->{_data}->insert;
	$log->debug("new Operation inserted.");

	$log->debug("new operation $args{op} inserted with his entity relation.");
}

1;
