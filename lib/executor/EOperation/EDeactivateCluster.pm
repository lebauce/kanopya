# EDeactivateCluster.pm - Operation class implementing cluster deactivation operation

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

EOperation::EDeactivateCluster - Operation class implementing cluster deactivation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster deactivation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeactivateCluster;
use base "EOperation";


use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Systemimage;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

    my $op = EOperation::EDeactivateCluster->new();

    # Operation::EDeactivateCluster->new creates a new DeactivateCluster operation.
    # RETURN : EOperation::EDeactivateCluster : Operation activate cluster on execution side

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

    $op->_init();
    # This private method is used to define some hash in Operation

=cut

sub _init {
    my $self = shift;
    $self->{_objs} = {};
    return;
}

sub checkOp{
    my $self = shift;
	my %args = @_;
    
    
    # check if cluster is active
    $log->debug("checking cluster active value <$args{params}->{cluster_id}>");
   	if(! $self->{_objs}->{cluster}->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::EDeactivateCluster->new : cluster $args{params}->{cluster_id} is already active";
	    	$log->error($errmsg);
	    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
}

=head2 prepare

	$op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

    # Check if internal_cluster exists
	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "EDeactivateCluster->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
    
    # Get Operation parameters
	my $params = $self->_getOperation()->getParams();
    $self->{_objs} = {};

 	# Cluster instantiation
    $log->debug("checking cluster existence with id <$params->{cluster_id}>");
    eval {
    	$self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
    };
    if($@) {
        my $err = $@;
    	$errmsg = "EOperation::EDeactivateCluster->prepare : cluster_id $params->{cluster_id} does not find\n" . $err;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    ### Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
		$errmsg = "Operation DeactivateCluster failed an error occured :\n$error";
		$log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	
	
	# set cluster active in db
	$self->{_objs}->{cluster}->setAttr(name => 'active', value => 0);
	$self->{_objs}->{cluster}->save();
		
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
