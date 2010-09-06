# EDeactiveSystemimage.pm - Operation class implementing systemimage deactivation operation

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

EOperation::EDeactiveSystemimage - Operation class implementing systemimage deactivation operation

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement systemimage deactivation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::EDeactiveSystemimage;

use strict;
use warnings;
use Log::Log4perl "get_logger";
use Data::Dumper;
use vars qw(@ISA $VERSION);
use base "EOperation";
use lib qw (/workspace/mcs/Executor/Lib /workspace/mcs/Common/Lib);
use McsExceptions;
use EFactory;
use Template;

my $log = get_logger("executor");
my $errmsg;
$VERSION = do { my @r = (q$Revision: 0.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

=head2 new

    my $op = EOperation::EDeactiveSystemimage->new();

	# Operation::EDeactiveSystemimage->new creates a new DeactiveSystemimage operation.
	# RETURN : EOperation::EDeactiveSystemimage : Operation deactive systemimage on execution side

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
		$errmsg = "EDeactiveSystemimage->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Mcs::Exception::Internal::IncorrectParam(error => $errmsg);
	}

	my $adm = Administrator->new();
	my $params = $self->_getOperation()->getParams();

	#### Instanciate Clusters
	$log->info("Get Internal Clusters");
	# Instanciate nas Cluster 
	$self->{nas}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{nas});
	$log->debug("Nas Cluster get with ref : " . ref($self->{nas}->{obj}));
	# Instanciate executor Cluster
	$self->{executor}->{obj} = $adm->getEntity(type => "Cluster", id => $args{internal_cluster}->{executor});
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
	$self->{_objs}->{systemimage} = $adm->getEntity(type => "Systemimage", id => $params->{systemimage_id});
	$log->debug("get systemimage self->{_objs}->{systemimage} of type : " . ref($self->{_objs}->{systemimage}));

	## Instanciate Component needed (here ISCSITARGET on nas )
	# Instanciate Export component.
	$self->{_objs}->{component_export} = EFactory::newEEntity(data => $self->{nas}->{obj}->getComponent(name=>"Iscsitarget",
																					  version=> "1",
																					  administrator => $adm));
	$log->info("Load export component (iscsitarget version 1, it ref is " . ref($self->{_objs}->{component_export}));

}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	$log->debug("After EOperation exec and before new Adm");
	my $adm = Administrator->new();
	
	my $sysimg_dev = $self->{_objs}->{systemimage}->getDevices();
	
	my $target_name = $sysimg_dev->{root}->{lvname};
	my $target_id = $self->{_objs}->{component_export}->_getEntity()->getTargetIdLike(iscsitarget1_target_name => '%'. $target_name);

	my $lun_id =  $self->{_objs}->{component_export}->_getEntity()->getLunId(iscsitarget1_target_id => $target_id,
												iscsitarget1_lun_device => "/dev/$sysimg_dev->{root}->{vgname}/$sysimg_dev->{root}->{lvname}");

	$self->{_objs}->{component_export}->removeLun(iscsitarget1_lun_id 	=> $lun_id,
												  iscsitarget1_target_id=>$target_id);
	$self->{_objs}->{component_export}->removeTarget(iscsitarget1_target_id		=>$target_id,
													 iscsitarget1_target_name 	=> $target_name,
													 econtext 					=> $self->{nas}->{econtext});
																  
	$self->{_objs}->{component_export}->reload();
		
	# set system image active in db
	$self->{_objs}->{systemimage}->setAttr(name => 'active', value => 0);
	$self->{_objs}->{systemimage}->save();
		
}

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
