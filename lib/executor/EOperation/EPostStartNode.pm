# EPostStartNode.pm - Operation class implementing Cluster creation operation

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

EEntity::Operation::EAddMotherboard - Operation class implementing Motherboard creation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement Motherboard creation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EPostStartNode;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Motherboard;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');
use Template;

my $log = get_logger("executor");
my $errmsg;

my $config = {
    INCLUDE_PATH => '/templates/internal/',
    INTERPOLATE  => 1,               # expand "$var" in plain text
    POST_CHOMP   => 0,               # cleanup whitespace 
    EVAL_PERL    => 1,               # evaluate Perl code blocks
    RELATIVE => 1,                   # desactive par defaut
};


=head2 new

    my $op = EOperation::EAddMotherboard->new();

	# Operation::EAddMotherboard->new creates a new AddMotheboard operation.
	# RETURN : EOperation::EAddMotherboard : Operation add motherboar on execution side

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
	$self->{nas} = {};
	$self->{executor} = {};
	$self->{bootserver} = {};
	$self->{monitor} = {};
	$self->{_objs} = {};
	return;
}

=head2 prepare

	$op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {
	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "EPostStartNode->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $params = $self->_getOperation()->getParams();

	#### No Cluster nor context to load 
	
	#### Get instance of Cluster Entity
	$log->info("Load cluster instance");
	$self->{_objs}->{cluster} = Entity::Cluster->get(id => $params->{cluster_id});
	$log->debug("get cluster self->{_objs}->{cluster} of type : " . ref($self->{_objs}->{cluster}));

	#### Get cluster components Entities
	$log->info("Load cluster component instances");
	$self->{_objs}->{components}= $self->{_objs}->{cluster}->getComponents(category => "all");
	$log->debug("Load all component from cluster");

	# Get instance of Motherboard Entity
	$log->info("Load Motherboard instance");
	$self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
	$log->debug("get Motherboard self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));
}

sub execute {
	my $self = shift;
	$self->SUPER::execute();
	
	if (not $self->{_objs}->{cluster}->getMasterNodeId()) {
		$self->{_objs}->{motherboard}->becomeMasterNode();
	}
	
	my $components = $self->{_objs}->{components};
	$log->info('Processing cluster components configuration for this node');
	foreach my $i (keys %$components) {
		
		my $tmp = EFactory::newEEntity(data => $components->{$i});
		$log->debug("component is ".ref($tmp));
		$tmp->postStartNode(motherboard => $self->{_objs}->{motherboard}, 
							cluster => $self->{_objs}->{cluster});
	}
	

}

#sub finish {
#    my $self = shift;
#    my $masternode;
#
#	if ($self->{_objs}->{cluster}->getMasterNodeId()) {
#		$masternode = 0;
#	} else {
#		$masternode =1;
#	}
#    
#	$self->{_objs}->{motherboard}->becomeMasterNode(master_node => $masternode);
#}
1;
__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
