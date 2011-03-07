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
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use EFactory;

use Entity::Cluster;
use Entity::Motherboard;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

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

sub checkOp{
    my $self = shift;
	my %args = @_;
	
    # check if motherboard is not active
    $log->debug("checking motherboard active value <$args{params}->{motherboard_id}>");
   	if($self->{_objs}->{motherboard}->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::EActivateMotherboard->new : motherboard $args{params}->{motherboard_id} is already active";
	    	$log->error($errmsg);
	    	throw Kanopya::Exception::Internal(error => $errmsg);
    }

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
	my $params = $self->_getOperation()->getParams();

	$self->{_objs} = {};
	$self->{nas} = {};
	$self->{executor} = {};

    # Instantiate motherboard and so check if exists
    $log->debug("checking motherboard existence with id <$params->{motherboard_id}>");
    eval {
    	$self->{_objs}->{motherboard} = Entity::Motherboard->get(id => $params->{motherboard_id});
    };
    if($@) {
    	$errmsg = "EOperation::EActivateMotherboard->new : motherboard_id $params->{motherboard_id} does not exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
		$errmsg = "Operation ActivateMotherboard failed an error occured :\n$error";
		$log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

	## Instanciate Clusters
	# Instanciate nas Cluster 
	$self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
	# Instanciate executor Cluster
	$self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});

	## Get Internal IP
	# Get Internal Ip address of Master node of cluster Executor
	my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
	# Get Internal Ip address of Master node of cluster nas
	my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
	
	
	## Instanciate context 
	# Get context for nas
	$self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);
		
	## Instanciate Component needed (here LVM and ISCSITARGET on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2");
	$log->debug("Value return by getcomponent ". ref($tmp));
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
	
}

sub execute{
	my $self = shift;
	$self->SUPER::execute();
	my ($powersupplycard,$powersupplyid);

	my $powersupplycard_id = $self->{_objs}->{motherboard}->getPowerSupplyCardId();
	if ($powersupplycard_id) {
		$powersupplycard = Entity::Powersupplycard(id => $powersupplycard_id);
		$powersupplyid = $self->{_objs}->{motherboard}->getAttr(name => 'motherboard_powersupply_id');
	}
	$self->{_objs}->{component_storage}->removeDisk(name => $self->{_objs}->{motherboard}->getEtcName(), econtext => $self->{nas}->{econtext});
	$self->{_objs}->{motherboard}->delete();
	if ($powersupplycard_id){
		$log->debug("Deleting powersupply with id <$powersupplyid> on the card : <$powersupplycard>");
		$powersupplycard->delPowerSupply(powersupply_id => $powersupplyid);
	}
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut