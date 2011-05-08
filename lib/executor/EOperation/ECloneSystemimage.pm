# ECloneSystemimage.pm - Operation class implementing System image cloning operation

#    Copyright © 2011 Hedera Technology SAS
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use String::Random;
use Date::Simple (':all');

use Kanopya::Exceptions;
use EFactory;
use Entity::Cluster;
use Entity::Motherboard;
use Template;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';

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

sub checkOp{
    my $self = shift;
	my %args = @_;
    
    
    # check if systemimage is not active
    $log->debug("checking source systemimage active value <".$self->{_objs}->{systemimage_source}->getAttr(name => 'systemimage_id').">");
   	if($self->{_objs}->{systemimage_source}->getAttr(name => 'active')) {
	    	$errmsg = "EOperation::ECloneSystemimage->checkop : systemimage <".$self->{_objs}->{systemimage_source}->getAttr(name => 'systemimage_id')."> is already active";
	    	$log->error($errmsg);
	    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    # check if systemimage name does not already exist
    $log->debug("checking unicity of systemimage_name <".$self->{_objs}->{systemimage}->getAttr(name=>'systemimage_name').">");
    if (defined Entity::Systemimage->getSystemimage(hash => {systemimage_name => $self->{_objs}->{systemimage}->getAttr(name=>'systemimage_name')})){
    	$errmsg = "Operation::ECloneSystemimage->prepare : systemimage_name ". $self->{_objs}->{systemimage}->getAttr(name=>'systemimage_name') ." already exist";
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal(error => $errmsg);
    }
	
	
	# check if vg has enough free space
    my $sysimg = $self->{_objs}->{systemimage_source};
    my $devices = $sysimg->getDevices;
    my $neededsize = $devices->{etc}->{lvsize} + $devices->{root}->{lvsize};
    $log->debug("Size needed for systemimage devices : $neededsize M"); 
    $log->debug("Freespace left : $devices->{etc}->{vgfreespace} M");
    if($neededsize > $devices->{etc}->{vgfreespace}) {
    	$errmsg = "EOperation::ECloneSystemimage->prepare : not enough freespace on vg $devices->{etc}->{vgname} ($devices->{etc}->{vgfreespace} M left)";
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

	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "ECloneSystemimage->prepare need an internal_cluster named argument!"; 
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
	
	my $params = $self->_getOperation()->getParams();
	$self->{_objs} = {};
	$self->{nas} = {};
	$self->{executor} = {};

    #### Get instance of Systemimage Entity
	$log->debug("Load systemimage instance");
    eval {
	   $self->{_objs}->{systemimage_source} = Entity::Systemimage->get(id => $params->{systemimage_id});
    };
    if($@) {
        my $err = $@;
    	$errmsg = "EOperation::EActivateSystemimage->prepare : systemimage_id $params->{systemimage_id} does not find\n" . $err;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
	$log->debug("get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));
	delete $params->{systemimage_id};
	$params->{distribution_id} = $self->{_objs}->{systemimage_source}->getAttr(name => 'distribution_id');


    #### Create new systemimage instance
	$log->debug("Create new systemimage instance");
    eval {
	   $self->{_objs}->{systemimage} = Entity::Systemimage->new(%$params);
    };
    if($@) {
        my $err = $@;
    	$errmsg = "EOperation::EAddSystemimage->prepare : wrong param during systemimage creation\n" . $err;
    	$log->error($errmsg);
    	throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
	$log->debug("get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));

    ### Check Parameters and context
    eval {
        $self->checkOp(params => $params);
    };
    if ($@) {
        my $error = $@;
		$errmsg = "Operation CloneSystemimage failed an error occured :\n$error";
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

	## Instanciate Component needed (here LVM on nas cluster)
	# Instanciate Cluster Storage component.
	my $tmp = $self->{nas}->{obj}->getComponent(name=>"Lvm",
										 version => "2");
	
	$self->{_objs}->{component_storage} = EFactory::newEEntity(data => $tmp);
	
}

sub execute {
	my $self = shift;

        my $devs = $self->{_objs}->{systemimage_source}->getDevices();
        my $etc_name = 'etc_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
        my $root_name = 'root_'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name');
        
        # creation of etc and root devices based on systemimage source devices
        $log->info('etc device creation for new systemimage');
        my $etc_id = $self->{_objs}->{component_storage}->createDisk(name       => $etc_name,
                                                                    size        => $devs->{etc}->{lvsize},
                                                                    filesystem  => $devs->{etc}->{filesystem},
                                                                    econtext    => $self->{nas}->{econtext},
                                                                    erollback   => $self->{erollback});
	   $log->info('etc device creation for new systemimage');													
	   my $root_id = $self->{_objs}->{component_storage}->createDisk(name => $root_name,
                                                                    size => $devs->{root}->{lvsize},
                                                                    filesystem => $devs->{root}->{filesystem},
                                                                    econtext => $self->{nas}->{econtext},
                                                                    erollback   => $self->{erollback});

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
	   $self->{_objs}->{systemimage}->cloneComponentsInstalledFrom(systemimage_source_id => $self->{_objs}->{systemimage_source}->getAttr(name => 'systemimage_id'));
       $log->info('System image <'.$self->{_objs}->{systemimage}->getAttr(name => 'systemimage_name') .'> is cloned');

}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut