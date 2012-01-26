# ECreateExport.pm - Operation class implementing component installation on systemimage

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
use Entity::Component::Iscsitarget1;
use EFactory;

my $log = get_logger("executor");
my $errmsg;
our $VERSION = '1.00';





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

    # test component_id presence
    if(! exists $params->{component_id} or ! defined $params->{component_id}) {
        $errmsg = "Operation::ECreateExport need a component_id parameter";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }

    # instanciate component and check its type
    my $component = Entity::Component->getInstance(id => $params->{component_id});
    $self->{component_name} = $component->getComponentAttr()->{component_name};
    if(!(($self->{component_name} eq 'Iscsitarget') or ($self->{component_name} eq 'Nfsd'))) {
        $errmsg = "Operation::ECreateExport need either a Iscstarget or Nfsd component";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
    }
    
    my $cluster_id =$component->getAttr(name => "cluster_id");
    $self->{_objs}->{cluster} = Entity::Cluster->get(id => $cluster_id);
    my ($state, $timestamp) = $self->{_objs}->{cluster}->getState();
    if ($state ne 'up'){
        $errmsg = "Cluster has to be up !";
        $log->error($errmsg);
        throw Kanopya::Exception::Internal::IncorrectParam(error => $errmsg);
    }
    
        
    ## TODO change this monstrous bevahior by another components management... 
    # BIG if here...
    if($self->{component_name} eq 'Iscsitarget') {
        
        if ((! exists $params->{export_name} or ! defined $params->{export_name})||
            (! exists $params->{device} or ! defined $params->{device})||
            (! exists $params->{typeio} or ! defined $params->{typeio})||
            (! exists $params->{iomode} or ! defined $params->{iomode})){
               $errmsg = "Operation ECreateExport failed for component $self->{component_name}, missing parameters";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
        $self->{params} = $params;
        $self->{_objs}->{ecomp_iscsitarget} = EFactory::newEEntity(data => $component);
    }    
    elsif($self->{component_name} eq 'Nfsd') {
        
        if ((! exists $params->{device} or ! defined $params->{device})||
            (! exists $params->{client_name} or ! defined $params->{client_name})||
            (! exists $params->{client_options} or ! defined $params->{client_options})){
               $errmsg = "Operation ECreateExport failed for component $self->{component_name}, missing parameters";
            $log->error($errmsg);
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
        $self->{params} = $params;
        $self->{_objs}->{ecomp_nfsd} = EFactory::newEEntity(data => $component);
    }
    
    $self->{executor}->{obj} = Entity::Cluster->get(id => $args{internal_cluster}->{executor});
    my $exec_ip = $self->{executor}->{obj}->getMasterNodeIp();
    my $masternode_ip = $self->{_objs}->{cluster}->getMasterNodeIp();
    $self->{cluster_econtext} = EFactory::newEContext(ip_source => $exec_ip, ip_destination => $masternode_ip);

}

sub execute{
    my $self = shift;
    
    # other big if...
    if($self->{component_name} eq 'Iscsitarget') {
        $self->{_objs}->{ecomp_iscsitarget}->createExport('export_name' => $self->{params}->{export_name},
                                                          'econtext'    => $self->{cluster_econtext},
                                                          'device_name' => $self->{params}->{device},
                                                          'typeio'      => $self->{params}->{typeio},
                                                          'iomode'      => $self->{params}->{iomode},
                                                          'erollback'   => $self->{erollback});
#        my $disk_targetname = $self->{_objs}->{ecomp_iscsitarget}->generateTargetname(name => $self->{params}->{export_name});
#
#        $self->{_objs}->{ecomp_iscsitarget}->addExport(iscsitarget1_lun_number    => 0,
#                                                      iscsitarget1_lun_device    => $self->{params}->{device},
#                                                      iscsitarget1_lun_typeio    => $self->{params}->{typeio},
#                                                      iscsitarget1_lun_iomode    => $self->{params}->{iomode},
#                                                      iscsitarget1_target_name  => $disk_targetname,
#                                                      econtext                 => $self->{cluster_econtext},
#                                                      erollback               => $self->{erollback});
#        my $eroll_add_export = $self->{erollback}->getLastInserted();
#
#        $self->{erollback}->insertNextErollBefore(erollback=>$eroll_add_export);
#        $self->{_objs}->{ecomp_iscsitarget}->generate(econtext  => $self->{cluster_econtext},
#                                                      erollback => $self->{erollback});
#        $log->info("Add IScsi Export of device <$self->{params}->{device}>");
    }
    
    elsif($self->{component_name} eq 'Nfsd') {
        my $export_id = $self->{_objs}->{ecomp_nfsd}->addExport(
            device => $self->{params}->{device},
            econtext =>  $self->{cluster_econtext}
        );
         $self->{_objs}->{ecomp_nfsd}->addExportClient(
             
             export_id => $export_id,
             client_name => $self->{params}->{client_name},
             client_options => $self->{params}->{client_options}
         );
        
        $self->{_objs}->{ecomp_nfsd}->update_exports(econtext => $self->{cluster_econtext});
        $log->info("Add NFS Export of device <$self->{params}->{device}>");
    }
    
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
