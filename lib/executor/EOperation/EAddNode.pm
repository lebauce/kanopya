# Copyright © 2010-2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EOperation::EAddNode;
use base "EOperation";

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::ServiceProvider::Inside::Cluster;
use Entity::Masterimage;
use Entity::Systemimage;
use Entity::Host;
use CapacityManagement;
use Workflow;
use Log::Log4perl "get_logger";
use Data::Dumper;
my $log = get_logger("executor");
my $errmsg;


sub prerequisites {
    my ($self, %args) = @_;
    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    if (defined $self->{params}->{remediation_workflow_id}){

        my $wf = Workflow->get(id => $self->{params}->{remediation_workflow_id});
        $log->info('REMEDIATION WORKFLOW <'.($self->{params}->{remediation_workflow_id}).'> STATE <'.($wf->getAttr(name => 'state')).'> ');

        if($wf->getAttr(name => 'state') eq 'cancelled') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> cancelled, EXCEPTION');
            throw Kanopya::Exception::Internal(error => 'Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> has been cancelled');
        }
        elsif ($wf->getAttr(name => 'state') eq 'done') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> done, let us continue');
            # HERE NO RETURN => CONTINUE AFTER THE IF
        }
        elsif ($wf->getAttr(name => 'state') eq 'running') {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> still running, waiting for its end');
            return 20;
        }
        else {
            $log->info('Remediation workflow <'.($self->{params}->{remediation_worfklow_id}).'> status unknown : '.($wf->getAttr(name => 'state')).', EXCEPTION');
            throw Kanopya::Exception::Internal(error => 'Remediation workflow <'.($self->{params}->{remediation_workflow_id}).'> has been cancelled');
        }
   }

   my $cluster = $self->{context}->{cluster};
   my $host_type = $cluster->getHostManager()->getHostType();

   $log->info("#########<$host_type>############");

   if($host_type eq 'Virtual Machine') {
       my $host_manager_params = $cluster->getManagerParameters(manager_type => 'host_manager');
       my $cm = CapacityManagement->new(cluster_id => $cluster->getId());

       my $hypervisor_id = $cm->getHypervisorIdForVM(
                                 wanted_values => {
                                     ram => $host_manager_params->{ram},
                                     cpu => $host_manager_params->{cpu},
                                 }
       );
       if(defined $hypervisor_id){
            $log->info('HYPERVISOR READY ('.($hypervisor_id).') OK ');
            return 0;
       } else {
            $log->info('NEED TO START A NEW HYPERVISOR');

            my $opennebula = $cluster->getManager(manager_type => 'host_manager');
            my $hv_cluster = $opennebula->getServiceProvider();
            my $wf = $hv_cluster->addNode();
            $self->{params}->{remediation_workflow_id} = $wf->getAttr(name => 'workflow_id');
            $log->info('LAUNCH REMEDIATION WORKFLOW ID = '.($self->{params}->{remediation_workflow_id}));
            return 15;
        }
   }
   else {   #Physical
       return 0
   }
}
=head2 prepare

    $op->prepare();

=cut

sub prepare {
    my $self = shift;
    my %args = @_;
    $self->SUPER::prepare();
    General::checkParams(args => $self->{context}, required => [ "cluster" ]);

    # Get the disk manager for disk creation
    my $disk_manager = $self->{context}->{cluster}->getManager(manager_type => 'disk_manager');
    $self->{context}->{disk_manager} = EFactory::newEEntity(data => $disk_manager);

    # Get the export manager for disk creation
    my $export_manager = $self->{context}->{cluster}->getManager(manager_type => 'export_manager');
    $self->{context}->{export_manager} = EFactory::newEEntity(data => $export_manager);

    # Get the masterimage for node systemimage creation.
    my $masterimage =  Entity::Masterimage->get(id => $self->{context}->{cluster}->getAttr(name => 'masterimage_id'));
    $self->{context}->{masterimage} = EFactory::newEEntity(data => $masterimage);

    # Check if a host is specified.
    if (defined $self->{context}->{host}) {
        my $host_manager_id = $self->{context}->{host}->getAttr(name => 'host_manager_id');
        my $cluster_host_manager_id = $self->{context}->{cluster}->getManager(manager_type => 'disk_manager')->getId;

        # Check if the specified host is managed by the cluster host manager
        if ($host_manager_id != $cluster_host_manager_id) {
            $errmsg = "Specified host <$args{host_id}>, is not managed by the same " .
                      "host manager than the cluster one (<$host_manager_id>)" .
                      " ne <$cluster_host_manager_id).";
            throw Kanopya::Exception::Internal::WrongValue(error => $errmsg);
        }
    }

    $self->{params}->{node_number} = $self->{context}->{cluster}->getNewNodeNumber();
    $log->debug("Node number for this new node: $self->{params}->{node_number} ");

    my $systemimage_name = $self->{context}->{cluster}->getAttr(name => 'cluster_name') . '_' .
                           $self->{params}->{node_number};

    # Check for existing systemimage for this node.
    my $existing_image;
    eval {
        $existing_image = Entity::Systemimage->find(hash => {systemimage_name => $systemimage_name});
    };

    # If systemimage context defined, force to use it.
    # If systemimage already exist for this node, use it.
    if (not $self->{context}->{systemimage}) {
        if ($existing_image) {
            $log->info("Using existing systemimage instance <$systemimage_name>");
            $self->{context}->{systemimage} = EFactory::newEEntity(data => $existing_image);
        }
        # Else if it is the first node, or the cluster si policy is dedicated, create a new one.
        elsif (($self->{params}->{node_number} == 1) or (not $self->{context}->{cluster}->getAttr(name => 'cluster_si_shared'))) {
            $log->info("Create new systemimage instance <$systemimage_name>");
    
            my $systemimage_desc = 'System image for node ' . $self->{params}->{node_number}  .' in cluster ' .
                                   $self->{context}->{cluster}->getAttr(name => 'cluster_name') . '.';

            eval {
               my $entity = Entity::Systemimage->new(
                                systemimage_name => $systemimage_name,
                                systemimage_desc => $systemimage_desc,
                            );
               $self->{context}->{systemimage} = EFactory::newEEntity(data => $entity);
            };
            if($@) {
                throw Kanopya::Exception::Internal::WrongValue(error => $@);
            }
            $self->{params}->{create_systemimage} = 1;
        }
        # Else if it is the firest node, or the cluster si policy is dedicated, create a new one.
        else {
            $self->{context}->{systemimage} = EFactory::newEEntity(
                                                  data => $self->{context}->{cluster}->getMasterNodeSystemimage
                                              );
        }
    }
}

sub execute {
    my $self = shift;
    $self->SUPER::execute();

    if (not defined $self->{context}->{host}) {
        # Just call Master node addition, other node will be add by the state manager
        $self->{context}->{host} = $self->{context}->{cluster}->addNode();
    }
    $self->{context}->{host}->setState(state => "locked");

    # If it is the first node, the cluster is starting
    if ($self->{params}->{node_number} == 1) {
        $self->{context}->{cluster}->setState(state => 'starting');
        $self->{context}->{cluster}->save();
    }

    # Create system image for node if required.
    if ($self->{params}->{create_systemimage}) {
        $self->{context}->{systemimage}->createFromMasterimage(
            masterimage    => $self->{context}->{masterimage},
            disk_manager   => $self->{context}->{disk_manager},
            manager_params => $self->{context}->{cluster}->getManagerParameters(manager_type => 'disk_manager'),
            erollback      => $self->{erollback},
        );
    }

    # Export system image for node if required.
    if (not $self->{context}->{systemimage}->getAttr(name => 'active')) {
        $self->{context}->{systemimage}->activate(
            export_manager => $self->{context}->{export_manager},
            manager_params => $self->{context}->{cluster}->getManagerParameters(manager_type => 'export_manager'),
            erollback      => $self->{erollback},
        );
    }
}

sub finish {
    my $self = shift;

    # Not not require masterimage in context any more.
    delete $self->{context}->{masterimage};

    # Not not require storage managers in context any more.
    delete $self->{context}->{disk_manager};
    delete $self->{context}->{export_manager};
}

sub _cancel {
    my $self = shift;

    if ($self->{context}->{cluster}) {
        my $hosts = $self->{context}->{cluster}->getHosts();
        if (! scalar keys %$hosts) {
            $self->{context}->{cluster}->setState(state => "down");
        }
    }

    if ($self->{context}->{host}) {
        $self->{context}->{host}->setState(state => "down");   
    }
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010-2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
