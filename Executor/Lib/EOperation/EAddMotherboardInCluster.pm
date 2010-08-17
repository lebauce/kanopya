# EAddMotherboardInCluster.pm - Operation class implementing Cluster creation operation

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
package EOperation::EAddMotherboardInCluster;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw (/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use EFactory;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EOperation::EAddMotherboard->new();

	# Operation::EAddMotherboard->new creates a new AddMotheboard operation.
	# RETURN : EOperation::EAddMotherboard : Operation add motherboar on execution side

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
    $log->warn("Class is : $class");
    my $self = $class->SUPER::new(%args);
    $self->_init();
    
    return $self;
}

=head2 _init

	$op->_init();
	# This private method is used to define internal parameters.

=cut

sub _init {
	my $self = shift;

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
		throw Mcs::Exception::Internal::IncorrectParam(error => "EAddMotherboardInCluster->prepare need an internal_cluster named argument!"); }

	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	$self->{nas} = {};
	$self->{executor} = {};
	$self->{_objs} = {};
	
	## Get Internal IP
	# Get Internal Ip address of Master node of cluster Executor
	my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
	# Get Internal Ip address of Master node of cluster nas
	my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
	
	
	## Instanciate context 
	# Get context for nas
	$self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);
	$self->{econtext} = EFactory::newEContext(ip_source => "127.0.0.1", ip_destination => "127.0.0.1");

	# Get instance of Cluster Entity
	$log->warn("Load cluster instance");
	$self->{_objs}->{cluster} = $adm->getEntity(type => "Cluster", id => $params->{cluster_id});
	$log->debug("get cluster self->{_objs}->{cluster} of type : " . ref($self->{_objs}->{cluster}));

	# Get instance of Motherboard Entity
	$log->warn("Load Motherboard instance");
	$self->{_objs}->{motherboard} = $adm->getEntity(type => "Motherboard", id => $params->{motherboard_id});
	$log->debug("get Motherboard self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));
	
	## Instanciate Component needed (here LVM, ISCSITARGET, DHCP on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2",
										 administrator => $adm);
	$log->debug("Value return by getcomponent ". ref($tmp));
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
	$log->debug("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));
	# Instanciate Cluster Export component.
	$self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
																					  version=> "1",
																					  administrator => $adm));
	
}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	my $adm = Administrator->new();
	$log->debug("After Adm");
	
	#TODO Clone the cluster etc
	#TODO Update export (etc, root, mount_point)
	#TODO Foreach component migrate (node, exec context?)
	#
# Create cluster directory

	#TODO Create node !
	#TODO Where will we determine if motherboard is masternode
	$adm->createNode(motherboard_id => $self->{_objs}->{motherboard}->getAttr(name=>"motherboard_id"),
					 cluster_id => $self->{_objs}->{cluster}->getAttr(name=>"cluster_id"),
					 master_node => 0);
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut