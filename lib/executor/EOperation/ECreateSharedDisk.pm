# EcreateSharedDisk.pm - Operation class implementing System image cloning operation

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

EEntity::EOperation::ECreateSharedDisk - Operation class implementing System image cloning operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image cloning operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::ECreateSharedDisk;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use Kanopya::Exceptions;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EOperation::ECreateSharedDisk->new();

EOperation::ECreateSharedDisk->new creates a new ECreateSharedDisk operation.

=cut

sub new {
    my $class = shift;
    my %args = @_;
    
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

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "ECreateSharedDisk->prepare need an internal_cluster named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $adm = Administrator->new();
	my $op_params = $self->_getOperation()->getParams();

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

	## Instanciate Component needed (here LVM on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2",
										 administrator => $adm);
	$self->{_objs}->{ecomponent_storage} = EFactory::newEEntity(data => $tmp);
	
	$tmp = $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
										 version => "1",
										 administrator => $adm);
	$self->{_objs}->{ecomponent_export} = EFactory::newEEntity(data => $tmp);

	#### Get instance of Cluster Entity
	$self->{_objs}->{cluster} = $adm->getEntity(type => "Cluster", id => $op_params->{cluster_id});
	$log->debug("get cluster self->{_objs}->{cluster} of type : " . ref($self->{_objs}->{cluster}));

	#TODO Get component from id ?
	$self->{_objs}->{component_export_client} = $self->{_objs}->{cluster}->getComponent(name=>"Openiscsi",
										 version => "2",
										 administrator => $adm);
}

sub execute {
	my $self = shift;
	$self->SUPER::execute();
	my $adm = Administrator->new();
	
	# Do we get params only during the prepare ? Or could we get it during execute?
	my $op_params = $self->_getOperation()->getParams();
	my $clustname = $self->{_objs}->{cluster}->getAttr(name => "cluster_name");
	$self->{_objs}->{ecomponent_storage}->createDisk(name		=> $op_params->{disk_name} . "_" . $clustname,
													 size		=> $op_params->{disk_size},
													 filesystem	=> $op_params->{disk_fs},
													 econtext	=> $self->{nas}->{econtext});
	my $disk_targetname = $self->{_objs}->{ecomponent_export}->generateTargetname(name => $op_params->{disk_name} . "_" . $clustname);
	$self->{_objs}->{ecomponent_export}->addTarget(targetname		=> $disk_targetname,
												   mount_point		=> "unused",
												   mount_options	=> "unused",
												   econtext			=> $self->{nas}->{econtext});
	$self->{_objs}->{component_export_client}->addSharedDisk(iscsitarget	=> $disk_targetname,
															 server			=> $self->{nas}->{obj}->getMasterNodeIp(),
															 port			=> "3260",
															 mount_point	=> $op_params->{mount_point},
															 mount_options	=> $op_params->{mount_options},
															 filesystem		=> $op_params->{disk_fs});
	
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut