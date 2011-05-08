# EOperation.pm - 

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 14 july 2010

=head1 NAME

EOperation - Abstract class of EOperation object.

=head1 SYNOPSIS

    my $operation = Operation->getNexOp();
    my $eoperation = EOperation->new(data => $operation);

=head1 DESCRIPTION

EOperation is an abstract class of different operations available in kanopya executor.
Each eoperation could be composed by the following methods.
- prepare (pre-execution)
- execute
- finish (post-execution)
EOperations contain :
- _operation : Operation : Operation send by user (human or software).
This attribute is Operation created by user and saved in database. 
This operation is loaded from database by EFactory and stored into EOperation
- duration_report : Scalar (Int) : Default 20  : Report time duration. 
It is time waited by operation when it is reported.

=head1 METHODS

=cut
package EOperation;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use ERollback;
use General;
use Entity::Cluster;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

=head2 _getOperation

	Class : Private
	
	Desc : This function return _operation (type : Operation) stored into EOperation.
	
	args: None
	
	return : Operation : a hashref containing 2 hashref, global attrs and extended ones

=cut

sub _getOperation{
	my $self = shift;
	return $self->{_operation};
}

=head2 new

	Class : Public
	
	Desc : This abstract method creates a new eoperation object.
	
	Args :
		data : Operation : Operation get from Database)
		
	Return : Eoperation, this class could not be instanciated !!
	

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    if ((! exists $args{data} or ! defined $args{data})) { 
		$errmsg = "EOperation->new ($class) need a data named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
   	}
    
    
   	$log->debug("Class is : $class");
    my $self = { 
    	_operation => $args{data},
    	duration_report => 20 	# default duration to wait during operation reporting (in seconds) 
    };
    bless $self, $class;
	$self->_init();

    return $self;
}

=head2 _init

	Class : Private
	
	Desc : This is a private method used to define internal parameters.
	
	Args :
            None
		
	Return : Nothing


=cut

sub _init {
	my $self = shift;
	$self->{internal_cluster} = {};
	return;
}

=head2 prepare

	Class : Public
	
	Desc : This method is the first method execute during eoperation execution.
	Its goal is to prepare the operation execution. In this method args are
	checked, entities and eentities need by operation execution 
	( ex : cluster, motherboard, component, ecomponent, econtext ...) are load in $self
	
	Args :
		None
		
	Return : Nothing
	
	Throw

=cut

sub prepare {
	my $self = shift;
	
	my $id = $self->_getOperation();
	$log->debug("Class is : $id");
	$self->{userid} = $self->_getOperation()->getAttr(attr_name => "user_id");
	$log->debug("Change user by user_id : $self->{userid}");	
#	my $adm = Administrator->new();
	$self->{erollback} = ERollback->new();
	#$adm->changeUser(user_id => $self->{userid});
}

=head2 execute

	Class : Public
	
	Desc : This method is the real execution method.
	
	Args :
		None
		
	Return : Nothing
	
	Throw

=cut

#sub execute {}

sub process{
    	my $self = shift;
#	$self->SUPER::execute();
	my $adm = Administrator->new();

    eval {
        $self->execute();
    };
    if ($@){
        my $error = $@;
		$errmsg = "Operation <".ref($self)."> failed an error occured :\n$error\nOperation will be rollbacked";
		$log->error($errmsg);
		$self->{erollback}->undo();
        throw Kanopya::Exception::Execution::Rollbacked(error => $errmsg);

    }
}

=head2 finish

	Class : Public
	
	Desc : This method is the last execution operation method called. 
	It is used to clean and finalize operation execution
	
	Args :
		None
		
	Return : Nothing
	
	Throw

=cut
sub finish {}

sub report {
	my $self = shift;
	$log->debug("Reporting operation with duration_report : $self->{duration_report}");
	$self->_getOperation()->setHopedExecutionTime(value => $self->{duration_report});
}

sub delete {
	my $self = shift;
	my $adm = Administrator->new();
	$self->{_operation}->delete();	
}

sub execute {}

=head2
	
	Class : Public
	
	Desc : load in $self->{ args{service} }->{econtext} the context correponding to the specified service
	
	Args : service : service name (e.g. 'nas', 'bootserver', 'executor', 'monitor')
	
=cut

sub loadContext {
	my $self = shift;
	my %args = @_;
	
	General::checkParams( args => \%args, required => ['internal_cluster', 'service'] );
	
	# Retrieve executor ip (used for source all context)
	if (not defined $self->{exec_cluster_ip}) {
		my $exec_cluster = Entity::Cluster->get(id => $args{internal_cluster}->{'executor'});
		$self->{exec_cluster_ip} = $exec_cluster->getMasterNodeIp();
	}
	
	my $cluster = Entity::Cluster->get(id => $args{internal_cluster}->{$args{service}});
	my $serv_ip = $cluster->getMasterNodeIp();
	$self->{$args{service}}->{econtext} = EFactory::newEContext(ip_source => $self->{exec_cluster_ip}, ip_destination => $serv_ip);
	
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;