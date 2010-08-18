# ECloneSystemimage.pm - Operation class implementing System image cloning operation

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

EEntity::EOperation::ECloneSystemimage - Operation class implementing System image cloning operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement System image cloning operation

=head1 DESCRIPTION



=head1 METHODS

=cut
package EOperation::ECloneSystemimage;

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

    my $op = EOperation::ECloneSystemimage->new();

EOperation::ECloneSystemimage->new creates a new ECloneSystemimage operation.

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
		$errmsg = "ECloneSystemimage->prepare need an internal_cluster named argument!"; 
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
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

	# Get distribution from param
	$self->{_objs}->{systemimage_source} = $adm->getEntity(type => 'Systemimage', id => $op_params->{systemimage_id});
	delete $op_params->{systemimage_id};

	# Instanciate new Systemimage Entity
	$op_params->{distribution_id} = $self->{_objs}->{systemimage_source}->getAttr(name => 'distribution_id');
	$self->{_objs}->{systemimage} = $adm->newEntity(type => "Systemimage", params => $op_params);
		
	## Instanciate Component needed (here LVM on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2",
										 administrator => $adm);
	
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
	
}

sub execute {
	my $self = shift;
	$self->SUPER::execute();
	my $adm = Administrator->new();
		
	my $devs = $self->{_objs}->{systemimage_source}->getDevices();
	my $etc_name = 'etc_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
	my $root_name = 'root_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
	
	# creation of etc and root devices based on systemimage source devices
	$log->info('etc device creation for new systemimage');
	my $etc_id = $self->{_objs}->{component_storage}->createDisk(name => $etc_name,
													size => $devs->{etc}->{lvsize},
													filesystem => $devs->{etc}->{filesystem},
													econtext => $self->{nas}->{econtext});
	$log->info('etc device creation for new systemimage');													
	my $root_id = $self->{_objs}->{component_storage}->createDisk(name => $root_name,
													size => $devs->{root}->{lvsize},
													filesystem => $devs->{root}->{filesystem},
													econtext => $self->{nas}->{econtext});
	
	# copy of systemimage source data to systemimage devices												
	$log->info('etc device fill with systemimage source data for new systemimage');
	my $command = "dd if=/dev/$devs->{etc}->{vgname}/$devs->{etc}->{lvname} of=/dev/$devs->{etc}->{vgname}/$etc_name bs=1M";
	my $result = $self->{nas}->{econtext}->execute(command => $command);
	# TODO dd command execution result checking
	
	$log->info('root device fill with systemimage source data for new systemimage');
	$command = "dd if=/dev/$devs->{root}->{vgname}/$devs->{root}->{lvname} of=/dev/$devs->{root}->{vgname}/$root_name bs=1M";
	$result = $self->{nas}->{econtext}->execute(command => $command);
	# TODO dd command execution result checking
	
	$self->{_objs}->{systemimage}->setAttr(name => "etc_device_id", value => $etc_id);
	$self->{_objs}->{systemimage}->setAttr(name => "root_device_id", value => $root_id);
	$self->{_objs}->{systemimage}->setAttr(name => "active", value => 0);
		
	$self->{_objs}->{systemimage}->save();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut