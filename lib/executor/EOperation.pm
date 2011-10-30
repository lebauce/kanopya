package EOperation;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

use ERollback;
use General;
use Entity::Cluster;
use General;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

sub _getOperation{
    my $self = shift;
    return $self->{_operation};
}

sub new {
    my $class = shift;
    my %args = @_;
    
    General::checkParams(args => \%args,
                         required => ['data']);
    
       $log->debug("Class is : $class");
    my $self = { _operation         => $args{data},
                duration_report     => 20,
                # default duration to wait during operation reporting (in seconds) 
                internal_cluster    => {}
    };
    bless $self, $class;

    return $self;
}

sub prepare {
    my $self = shift;
    
    my $id = $self->_getOperation();
    
    $self->{userid} = $self->_getOperation()->getAttr(attr_name => "user_id");
#   To restore change user uncomment follow
#   $log->debug("Change user by user_id : $self->{userid}");    
#   my $adm = Administrator->new();
#   $adm->changeUser(user_id => $self->{userid});
    $self->{erollback} = ERollback->new();

}

sub process{
    my $self = shift;

    eval {
        $self->execute();
    };
    if ($@){
        my $error = $@;
        $errmsg = "Operation <".ref($self)."> failed an error occured :\n";
        $errmsg .= "$error\nOperation will be rollbacked";
        $log->error($errmsg);
        $self->{erollback}->undo();
        throw Kanopya::Exception::Execution::Rollbacked(error => $errmsg);
    }
}

sub cancel {
    my $self = shift;
    $self->{_operation}->{cancelled} = 1;
    $self->_cancel;
}

#interface
sub _cancel {}
sub finish {}
sub execute {}

sub report {
    my $self = shift;
    $log->debug("Reporting operation with duration_report : $self->{duration_report}");
    $self->_getOperation()->setHopedExecutionTime(value => $self->{duration_report});
}

sub delete {
    my $self = shift;

    $self->{_operation}->delete();
}

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
    $self->{$args{service}}->{ip} = $cluster->getMasterNodeIp();
    $self->{$args{service}}->{econtext} = EFactory::newEContext(ip_source => $self->{exec_cluster_ip}, ip_destination => $self->{$args{service}}->{ip});
    
}

1;

__END__

=pod

=head1 NAME

EOperation - Abstract class of EOperation object.

=head1 SYNOPSIS

    use EOperation;
    use Operation;

    my $operation = Operation->getNexOp();
    my $eoperation = EOperation->new(data => $operation);
    
    $self->{config} = XMLin("/opt/kanopya/conf/executor.conf");
    
    eval {
        $eoperation->prepare(internal_cluster => $self->{config}->{cluster});
        $eoperation->process();
    };
    if ($@) {
        $eoperation->cancel();
    } else {
        $o$eoperationp->finish();
    }
    $o$eoperationp->delete();

=head1 DESCRIPTION

EOperation is an abstract class of different operations available in kanopya executor.
Each eoperation could be composed by the following methods.
- prepare (pre-execution)
- process
- finish (post-execution)
EOperations contain :
- _operation : Operation : Operation send by user (human or software).
This attribute is Operation created by user and saved in database. 
This operation is loaded from database by EFactory and stored into EOperation
- duration_report : Scalar (Int) : Default 20  : Report time duration. 
It is time waited by operation when it is reported.

=head1 METHODS

=head2 _getOperation

    Class : Private
    
    Desc : This function return _operation (type : Operation) stored into EOperation.
    
    args: None
    
    return : Operation : a hashref containing 2 hashref, global attrs and extended ones

=head2 new

    Class : Public
    
    Desc : This abstract method creates a new eoperation object.
    
    Args :
        data : Operation : Operation (get from Database)
        
    Return : Eoperation, this class could not be instanciated !!

=head2 prepare

    Class : Public
    
    Desc : This method is the first method execute during eoperation execution.
    Its goal is to prepare the operation execution. In this method args are
    checked, entities and eentities need by operation execution 
    ( ex : cluster, motherboard, component, ecomponent, econtext ...) are load in $self
    
    Args :
        None
        
    Return : Nothing
    
=head2 process

    Class : Public
    
    Desc : This method is the real execution method.
    
    Args :
        None
        
    Return : Nothing
    
=head2 cancel

    Class : Public
    
    Desc : This method cancel changes done during process.
    DB will be rollback by the the transaction cancel
    To backup real change, cancel method call rollback 
    
    Args :
        None
        
    Return : Nothing
    
=head2 finish

    Class : Public
    
    Desc : This method is the last execution operation method called. 
    It is used to clean and finalize operation execution
    
    Args :
        None
        
    Return : Nothing
    
    Throw

=head2 loadContext
    
    Class : Public
    
    Desc : load in $self->{ args{service} }->{econtext} the context correponding to the specified service
    
    Args : service : service name (e.g. 'nas', 'bootserver', 'executor', 'monitor')
    

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

Copyright 2011 Hedera Technology SAS
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

