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

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw(/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

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

	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	# Get instance of Motherboard Entity
	$log->info("Load Motherboard instance");
	$self->{_objs}->{motherboard} = $adm->getEntity(type => "Motherboard", id => $params->{motherboard_id});
	
	# Get instance of Cluster Entity
	$log->info("Load cluster instance");
	$self->{_objs}->{cluster} = $adm->getEntity(type => "Cluster", id => $params->{cluster_id});
}

sub execute {
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	my $adm = Administrator->new();
	
	## halt the node
	my $motherboard_econtext = EFactory::newEContext(
		ip_source => "127.0.0.1", 
		ip_destination => $self->{_objs}->{motherboard}->getAttr(name => 'motherboard_internal_ip')
	);
	my $command = 'halt';
	my $result = $motherboard_econtext->execute(command => $command);
	my $state = 'stopping:'.time;
	$self->{_objs}->{motherboard}->setAttr(name => 'motherboard_state', value => $state);
	
	$adm->removeNode(motherboard_id => $self->{_objs}->{motherboard}->getAttr(name=>"motherboard_id"),
					 cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"));
	
	
	$self->{_objs}->{motherboard}->save();
	
	## add RemoveMotherboardFromCluster operation for this node
		
	$adm->newOp(
		type => 'RemoveMotherboardFromCluster',
		priority => 100, #TODO manager la priorite de l'operation autrement
		hoped_execution_time => 10,
		params => {
			cluster_id => $self->{_objs}->{cluster}->getAttr(name => "cluster_id"),
			motherboard_id => $self->{_objs}->{motherboard}->getAttr(name => "motherboard_id"),
		} 
	);
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut











