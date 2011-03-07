# EStopNode.pm - Operation class implementing stop node operation

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

EOperation::EStopNode - Operation class implementing stop node operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement stop node operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EStopNode;
use base "EOperation";

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Motherboard;

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("executor");
my $errmsg;

=head2 new

    my $op = EEntity::EOperation::EStopNode->new();

EOperation::EStopNode->new creates a new StopNode operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->debug("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 prepare

	$op->prepare();

=cut

sub prepare {
	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

	my $params = $self->_getOperation()->getParams();

	# Get instance of Motherboard Entity
	$log->info("Load Motherboard instance");
	$self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
	
	# Get instance of Cluster Entity
	$log->info("Load cluster instance");
	$self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
	
	$self->{_objs}->{components} = $self->{_objs}->{cluster}->getComponents(category => "all");
	
    # Get context for executor
	$self->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");
	$log->debug("Get econtext for executor with ref ". ref($self->{econtext}));
    # Get node context
	$self->{node_econtext} = EFactory::newEContext(ip_source => "127.0.0.1",
	                                               ip_destination => $self->{_objs}->{motherboard}->getAttr(name => 'motherboard_internal_ip'));
	$log->debug("Get econtext for motherboard with ref ". ref($self->{node_econtext}));

}

sub execute {
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	my $adm = Administrator->new();
	
	my $components = $self->{_objs}->{components};
	$log->info('Processing cluster components configuration for this node');
	foreach my $i (keys %$components) {
		my $tmp = EFactory::newEEntity(data => $components->{$i});
		$log->debug("component is ".ref($tmp));
		$tmp->stopNode(motherboard => $self->{_objs}->{motherboard}, 
						cluster => $self->{_objs}->{cluster} );
	}
	# finaly we halt the node
	my $emotherboard = EFactory::newEEntity(data => $self->{_objs}->{motherboard});
	$emotherboard->halt(node_econtext =>$self->{node_econtext});

	$self->{_objs}->{motherboard}->setNodeState(state=>"goingout");
	$self->{_objs}->{motherboard}->save();

}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut











