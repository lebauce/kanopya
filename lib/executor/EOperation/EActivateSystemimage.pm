# EActivateSystemimage.pm - Operation class implementing Systemimage activation operation

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

EOperation::EActivateSystemimage - Operation class implementing systemimage activation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement systemimage activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EActivateSystemimage;
use base "EOperation";

use strict;
use warnings;

use Template;
use Log::Log4perl "get_logger";
use Data::Dumper;

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Systemimage;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

    my $op = EOperation::EActivateSystemimage->new();

	# Operation::EActivateSystemimage->new creates a new ActivateSystemimage operation.
	# RETURN : EOperation::EActivateSystemimage : Operation active systemimage on execution side

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
		$errmsg = "EActivateSystemimage->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $params = $self->_getOperation()->getParams();

	#### Instanciate Clusters
	$log->info("Get Internal Clusters");
	# Instanciate nas Cluster 
	$self->{nas}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{nas});
	$log->debug("Nas Cluster get with ref : " . ref($self->{nas}->{obj}));
	# Instanciate executor Cluster
	$self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});
	$log->debug("Executor Cluster get with ref : " . ref($self->{executor}->{obj}));
		
	#### Get Internal IP
	$log->info("Get Internal Cluster IP");
	# Get Internal Ip address of Master node of cluster Executor
	my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
	$log->debug("Executor ip is : <$exec_ip>");
	# Get Internal Ip address of Master node of cluster nas
	my $nas_ip = $self->{nas}->{obj}->getMasterNodeIp();
	$log->debug("Nas ip is : <$nas_ip>");
	
	#### Instanciate context 
	$log->info("Get Internal Cluster context");
	# Get context for nas
	$self->{nas}->{econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $nas_ip);
	$log->debug("Get econtext for nas with ip ($nas_ip) and ref " . ref($self->{nas}->{econtext}));
	
	#### Get instance of Systemimage Entity
	$log->info("Load systemimage instance");
	$self->{_objs}->{systemimage} = Entity::Systemimage->get(id => $params->{systemimage_id});
	$log->debug("get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));

	## Instanciate Component needed (here ISCSITARGET on nas )
	# Instanciate Export component.
	$self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
																					  version=> "1"));
	$log->info("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));


}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	
	## Update export to allow to motherboard to boot with this systemimage
	my $target_name = $self->{_objs}->{component_export}->generateTargetname(name => 'root_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name'));

	# Get etc iscsi target information
	my $sysimg_dev = $self->{_objs}->{systemimage}->getDevices();
	my $sysimg_root_export = {
		iscsitarget1_target_name=>$target_name,
		mountpoint=>"/",
		mount_option=>""
	};
		
	$sysimg_root_export->{econtext} = $self->{nas}->{econtext};
	my $target_id = $self->{_objs}->{component_export}->addTarget(%$sysimg_root_export);
	delete $sysimg_root_export->{econtext};															  
	$self->{_objs}->{component_export}->addLun(iscsitarget1_target_id	=> $target_id,
												iscsitarget1_lun_number	=> 0,
												iscsitarget1_lun_device	=> "/dev/$sysimg_dev->{root}->{vgname}/$sysimg_dev->{root}->{lvname}",
												iscsitarget1_lun_typeio	=> "fileio",
												iscsitarget1_lun_iomode	=> "ro",
												iscsitarget1_target_name=>$target_name,
												econtext 				=> $self->{nas}->{econtext});
	# generate new configuration file
	$self->{_objs}->{component_export}->generate(econtext => $self->{nas}->{econtext});
		
	# set system image active in db
	$self->{_objs}->{systemimage}->setAttr(name => 'active', value => 1);
	$self->{_objs}->{systemimage}->save();
		
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
