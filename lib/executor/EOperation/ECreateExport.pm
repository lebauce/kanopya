# ECreateExport.pm - Operation class implementing component installation on systemimage

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

EOperation::ECreateExport - Operation class implementing component installation on systemimage

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ECreateExport;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Component::Export::Iscsitarget1;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

    my $op = EOperation::ECreateExport->new();

    # Operation::ECreateExport->new installs component on systemimage.
    # RETURN : EOperation::ECreateExport : Operation activate cluster on execution side

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
    $self->{_objs} = {};
    return;
}

sub checkOp{
    my $self = shift;
	my %args = @_;
    
    

}

=head2 prepare

	$op->prepare(internal_cluster => \%internal_clust);

=cut

sub prepare {	
	my $self = shift;
	my %args = @_;
	$self->SUPER::prepare();

	$log->info("Operation preparation");

    # Check if internal_cluster exists
	if (! exists $args{internal_cluster} or ! defined $args{internal_cluster}) { 
		$errmsg = "ECreateExport->prepare need an internal_cluster named argument!";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
	}
    
    # Get Operation parameters
	my $params = $self->_getOperation()->getParams();
    $self->{_objs} = {};

    if ((! exists $params->{component_instance_id} or ! defined $params->{component_instance_id}) ||
        (! exists $params->{export_name} or ! defined $params->{export_name})||
        (! exists $params->{device} or ! defined $params->{device})||
        (! exists $params->{typeio} or ! defined $params->{typeio})||
        (! exists $params->{iomode} or ! defined $params->{iomode})){
        my $error = $@;
		$errmsg = "Operation ECreateExport failed, missing parameters";
		$log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    $self->{params} = $params;
    # Test if component instance id is really a Entity::Component::Export::Iscsitarget
    my $comp_iscsitarget = Entity::Component::Export::Iscsitarget1->get(id => $params->{component_instance_id});
    my $comp_desc = $comp_iscsitarget->getComponentAttr();
    if (! $comp_desc->{component_name} eq "Iscsitarget") {
		$errmsg = "ECreateExport->prepare need id of a iscsitarget component !";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    $self->{_objs}->{ecomp_iscsitarget} = EFactory::newEEntity(data => $comp_iscsitarget);
    my $cluster_id =$comp_iscsitarget->getAttr(name => "cluster_id");
    $self->{_objs}->{cluster} = Entity::Cluster->get(id => $cluster_id);
    if (!($self->{_objs}->{cluster}->getAttr(name=>"cluster_state") eq "up")){
        $errmsg = "Cluster has to be up !";
		$log->error($errmsg);
		throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
     # Instanciate executor Cluster
	$self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});
    
    my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
    my $masternode_ip = $self->{_objs}->{cluster}->getMasterNodeIp();
	$self->{cluster_econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $masternode_ip);

}

sub execute{
	my $self = shift;
	$log->debug("Before EOperation exec");
	$self->SUPER::execute();
	
	my $disk_targetname = $self->{_objs}->{ecomp_iscsitarget}->generateTargetname(name => $self->{params}->{export_name});
	my $target_id = $self->{_objs}->{ecomp_iscsitarget}->addTarget(
	                                               iscsitarget1_target_name		=> $disk_targetname,
												   mountpoint		=> "unused",
												   mount_option	=> "unused",
												   econtext			=> $self->{cluster_econtext});
	$self->{_objs}->{ecomp_iscsitarget}->addLun(iscsitarget1_lun_number => 0,
	                                            iscsitarget1_lun_device => $self->{params}->{device},
	                                            iscsitarget1_target_id => $target_id,
	                                            iscsitarget1_lun_typeio => $self->{params}->{typeio},
	                                            iscsitarget1_lun_iomode => $self->{params}->{iomode},
	                                            iscsitarget1_target_name => $disk_targetname,
	                                            econtext			=> $self->{cluster_econtext});
$self->{_objs}->{ecomp_iscsitarget}->generate(econtext => $self->{cluster_econtext});
}

=head1 DIAGNOSTICS

Exceptions are thrown when mandatory arguments are missing.
Exception : Kanopya::Exception::Internal::IncorrectParam

=head1 CONFIGURATION AND ENVIRONMENT

This module need to be used into Kanopya environment. (see Kanopya presentation)
This module is a part of Administrator package so refers to Administrator configuration

=head1 DEPENDENCIES

This module depends of 

=over

=item KanopyaException module used to throw exceptions managed by handling programs

=item Entity::Component module which is its mother class implementing global component method

=back

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

<HederaTech Dev Team> (<dev@hederatech.com>)

=head1 LICENCE AND COPYRIGHT

Kanopya Copyright (C) 2009, 2010, 2011, 2012, 2013 Hedera Technology.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301 USA.

=cut

1;