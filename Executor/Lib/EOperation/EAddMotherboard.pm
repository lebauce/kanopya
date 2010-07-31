# EAddMotherboard.pm - Operation class implementing Motherboard creation operation

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
package EOperation::EAddMotherboard;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw(.. ../../../Common/Lib);
use McsExceptions;

my $log = get_logger("executor");

$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EEntity::EOperation::EAddMotherboard->new();

EEntity::Operation::EAddMotherboard->new creates a new AddMotheboard operation.

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
	my $args = @_;
	$self->SUPER::prepare();

		$log->warn("After Eoperation prepare and before get Administrator singleton");
	my $adm = Administrator->new();
#	my $exec = Executor->new();
	my $params = $self->_getOperation()->getParams();

	$self->{_objs} = {};

	# Get Storage Cluster
	$log->debug("Get Nas internal cluster");
#	my $c_cstorage = $exec->getInternalCluster(clustertype => "nas");
	$self->{internal_cluster} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{nas});

	# Instanciate new Motherboard Entity
	$log->warn("adm->newEntity of Motherboard");
	$self->{_objs}->{motherboard} = $adm->newEntity(type => "Motherboard", params => $params);
	$log->warn("New motherboard self->{_objs}->{motherboard} of type : " . ref($self->{_objs}->{motherboard}));
	
	# Instanciate Cluster Storage component.
	my $tmp = $c_cstorage->getComponent(name=>"Lvm",
									   version => "2",
									   administrator => $adm);
	print "Value return by getcomponent ". ref($tmp);
	$self->{_objs}->{component_storage} = EEntityFactory::newEEntity(data => $tmp);
	$log->debug("Load Lvm component version 2, it ref is " . ref($self->{_objs}->{component_storage}));

	$self->{_objs}->{component_export} = EEntityFactory::newEEntity(data => $c_cstorage->getComponent(name=>"Iscsitarget",
																					  version=> "1",
																					  administrator => $adm));
	$log->debug("Load Iscsitarget component version 1, it ref is " . ref($self->{_objs}->{component_export}));
}

sub execute{
	my $self = shift;
	$self->SUPER::execute();

	# Set initiatorName
	$self->{_objs}->{motherboard}->setAttr(name => "motherboard_initiatorname",
										   value => $self->{_objs}->{component_export}->generateInitiatorname(id => $self->{_objs}->{motherboard}));

}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut