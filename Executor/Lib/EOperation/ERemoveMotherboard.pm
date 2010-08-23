# ERemoveMotherboard.pm - Operation class implementing Motherboard creation operation

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
package EOperation::ERemoveMotherboard;

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
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EEntity::EOperation::ERemoveMotherboard->new();

EEntity::Operation::ERemoveMotherboard->new creates a new RemoveMotheboard operation.

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

	$op->_init() is a private method used to define internal parameters.

=cut

sub _init {
	my $self = shift;

	return;
}

=head2 prepare

	$op->prepare();

=cut

sub prepare {
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	if ((! exists $args{internal_cluster} or ! defined $args{internal_cluster})) { 
		$errmsg = "ERemoveMotherboard->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	$log->debug("After Eoperation prepare and before get Administrator singleton");
	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	$self->{_objs} = {};
	$self->{nas} = {};
	$self->{executor} = {};

	## Instanciate Clusters
	# Instanciate nas Cluster 
	$self->{nas}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{nas});
	# Instanciate executor Cluster
	$self->{executor}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{executor});

	## Get Internal IP
	# Get Internal Ip address of Master node of cluster Executor
	my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
	# Get Internal Ip address of Master node of cluster nas
	my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
	
	
	## Instanciate context 
	# Get context for nas
	$self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);


	# Instanciate new Motherboard Entity
	$self->{_objs}->{motherboard} = $adm->getEntity(type => "Motherboard", id => $params->{motherboard_id});
		
	## Instanciate Component needed (here LVM and ISCSITARGET on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2",
										 administrator => $adm);
	$log->debug("Value return by getcomponent ". ref($tmp));
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
	
}

sub execute{
	my $self = shift;
	$self->SUPER::execute();
	my $adm = Administrator->new();

	#TODO On aurait pu faire une méthode dans le EMotherboard permettant de créer son etc (rassemble les appelles de creation)
	#TODO Reflechir ou positionne-t-on nos prises de decisions arbitraires (taille d un disque etc, filesystem, ...) dans les objet en question ou dans les operations qui les utilisent
	$self->{_objs}->{component_storage}->removeDisk(name => $self->{_objs}->{motherboard}->getEtcName(), econtext => $self->{nas}->{econtext});
	# AddMotherboard finish, just save the Entity in DB
	$self->{_objs}->{motherboard}->delete();
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut