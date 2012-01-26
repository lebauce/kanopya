# ECreateLogicalVolume.pm - Operation class implementing component installation on systemimage

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

EOperation::ECreateLogicalVolume - Operation class implementing component installation on systemimage

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement cluster activation operation

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EOperation::ECreateLogicalVolume;
use base "EOperation";

use strict;
use warnings;

use Log::Log4perl "get_logger";
use Data::Dumper;
use Kanopya::Exceptions;
use Entity::Cluster;
use Entity::Component::Lvm2;;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';


=head2 new

    my $op = EOperation::ECreateLogicalVolume->new();

    # Operation::EInstallComponentInSystemImage->new installs component on systemimage.
    # RETURN : EOperation::EInstallComponentInSystemImage : Operation activate cluster on execution side

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
    $self->{executor} = {};
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

    # Check if internal_cluster exists
    General::checkParams(args => \%args, required => ["internal_cluster"]);
    
    # Get Operation parameters
    my $params = $self->_getOperation()->getParams();
    $self->{_objs} = {};
    

    General::checkParams(args => $params, required => ["component_id", "disk_name", "size", "filesystem", "vg_id"]);

    $self->{params} = $params;
    # Test if component instance id is really a Entity::Component::Iscsitarget
    my $comp_lvm = Entity::Component::Lvm2->get(id => $params->{component_id});
    my $comp_desc = $comp_lvm->getComponentAttr();
    if (! $comp_desc->{component_name} eq "Lvm") {
        $errmsg = "ECreateLogicalVolume->prepare need id of a lvm component !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    $self->{_objs}->{ecomp_lvm} = EFactory::newEEntity(data => $comp_lvm);
    my $cluster_id =$comp_lvm->getAttr(name => "cluster_id");
    $self->{_objs}->{cluster} = Entity::Cluster->get(id => $cluster_id);
    my ($state, $timestamp) = $self->{_objs}->{cluster}->getState();
    if ($state ne 'up'){
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
    
    my $adm = Administrator->new();
    $self->{_objs}->{ecomp_lvm}->createDisk(name       => $self->{params}->{disk_name},
                                            size       => $self->{params}->{size},
                                            filesystem => $self->{params}->{filesystem},
                                            econtext   => $self->{cluster_econtext},
                                            erollback  => $self->{erollback});

    $log->info("New Logical volume <" . $self->{params}->{disk_name} . "> created");
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
