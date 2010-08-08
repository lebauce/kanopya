# Operation.pm - Operation class, this is an abstract class

# Copyright (C) 2009, 2010, 2011, 2012, 2013
#   Free Software Foundation, Inc.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to the
# Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

Operation.pm - Operation class, this is an abstract class

=head1 SYNOPSIS

This Object represent an operation.

=head1 DESCRIPTION


=head1 METHODS

=cut

package Operation;

use strict;
use warnings;
use lib qw(../../Common/Lib);
use Log::Log4perl "get_logger";

use McsExceptions;

my $log = get_logger("administrator");

=head2 new
	
	Class : Public
	
	Desc : This method instanciate Operation.
	
	Args :
		rightschecker : Rightschecker : Object use to check write and update entity_id
		data : DBIx class: object data
		params : hashref : Operation parameters
	Return : Operation, this class could not be instanciated !!
	
=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data}) ||
		(! exists $args{rightschecker} or ! defined $args{rightschecker})||
		(! exists $args{params} or ! defined $args{params})) { 
		throw Mcs::Exception::Internal(error => "Entity->new need a data, params and rightschecker named argument!"); }
    
    # Here Check if users can execution this operation (We have the rightschecker)

    my $self = {
		_rightschecker => $args{rightschecker},
        _dbix => $args{data},
        _params => $args{params},
    };
    bless $self, $class;
    return $self;
}

=head2 cancel
	
	Class : Public
	
	Desc : This method delete Operation and its parameters
	
=cut

sub cancel {
	my $self = shift;

	my $params_rs = $self->{_dbix}->operation_parameters;
	$params_rs->delete;
	$self->{_dbix}->delete();
}

=head2 getAttr
	
	Class : Public
	
	Desc : This method return operation Attr specified in args
	
	args :
		attr_name : String : Attribute name
	
	Return : String : Parameter specified
	
=cut

sub getAttr {
	my $self = shift;
    my %args = @_;
	my $value;

	if (! exists $args{attr_name} or ! defined $args{attr_name}) { 
		throw Mcs::Exception::Internal(error => "Operation->getAttr need an attr named argument!"); }

	$log->info(ref($self) . " getAttr of $args{attr_name}");
	
	if ( $self->{_dbix}->has_column( $args{attr_name} ) ) {
		$value = $self->{_dbix}->get_column( $args{attr_name} );
		$log->info("  found value = $value");
	}
	else{
		throw Mcs::Exception::Internal(error => "Operation->getAttr : Wrong value asked!");
	}
	return $value;
}

=head2 getParams
	
	Class : Public
	
	Desc : This method returns all params 
	
	Return : hashref : all parameters of operation
=cut

sub getParams {
	my $self = shift;
	my %params;

	my $params_rs = $self->{_dbix}->operation_parameters;
	while (my $param = $params_rs->next){
		$params{$param->name} = $param->value;
	}
	return \%params;
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

	my $newentity = $self->{_dbix}->insert;
	my $params = $self->{_params};
	$log->debug("new Operation inserted.");

	foreach my $k (keys %$params) {
		$self->{_dbix}->create_related( 'operation_parameters', { name => $k, value => $params->{$k} } );}
	$log->debug("new operation $self inserted with his entity relation.");
}



1;
