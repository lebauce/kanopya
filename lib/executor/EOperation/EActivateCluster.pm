# EActivateCluster.pm - Operation class implementing Cluster activation operation

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

EOperation::EActivateCluster - Operation class implementing cluster activation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EActivateCluster;
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

    my $op = EOperation::EActivateCluster->new();

    # Operation::EActivateCluster->new creates a new ActivateCluster operation.
    # RETURN : EOperation::EActivateCluster : Operation activate cluster on execution side

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
    
    # check if system image used is active 
    $log->debug("checking cluster 's systemimage active value <$args{params}->{cluster_id}>");
    my $systemimage = Entity::Systemimage->get(id => $self->{_objs}->{cluster}->getAttr(name => 'systemimage_id'));
    if(not $systemimage->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::EActivateCluster->new : cluster's systemimage is not activated";
	    	$log->error($errmsg);
	    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if cluster is not active
    $log->debug("checking cluster active value <$args{params}->{cluster_id}>");
   	if($self->{_objs}->{cluster}->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::EActivateCluster->new : cluster $args{params}->{cluster_id} is already active";
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
		$errmsg = "EActivateCluster->prepare need an internal_cluster named argument!";
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
    	$errmsg = "EOperation::EActivateCluster->prepare : cluster_id $params->{cluster_id} does not find\n" . $err;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    ### Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
		$errmsg = "Operation ActivateCluster failed an error occured :\n$error";
		$log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	
	
	# set cluster active in db
	$self->{_objs}->{cluster}->setAttr(name => 'active', value => 1);
	$self->{_objs}->{cluster}->save();
		
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
