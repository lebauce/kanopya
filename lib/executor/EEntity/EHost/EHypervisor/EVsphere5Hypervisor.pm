#    Copyright © 2011-2012 Hedera Technology SAS
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

# Maintained by Dev Team of Hedera <>Technology <dev@hederatech.com>.

package EEntity::EHost::EHypervisor::EVsphere5Hypervisor;
use base "EEntity::EHost::EHypervisor";

use EFactory;

use strict;
use warnings;
use Data::Dumper;
use Log::Log4perl "get_logger";
use Hash::Merge qw(merge);

my $log = get_logger("executor");
my $errmsg;

=pod

=begin classdoc

Instanciate the vsphere component managing this hypervisor

@return vsphere

=end classdoc

=cut

sub getVsphereManager {
    my ($self,%args) = @_;

    my $vsphere = Entity->get(id => $self->vsphere5_id);

    return $vsphere;
}

=pod

=begin classdoc

=head2 getAvailableMemory

Query the hypervisor's available memory amount.

@return memory_available

=end classdoc

=cut

sub getAvailableMemory {
    my ($self,%args) = @_;

    #first we open a connection toward vsphere
    my $vsphere = $self->getVsphereManager();

    #get the hypervisor's datacenter
    my $datacenter = $self->vsphere5_datacenter;

    #get vsphere datacenter's view
    my $dc_view = $vsphere->findEntityView(
                      view_type   => 'Datacenter',
                      hash_filter => {
                          name => $datacenter->vsphere5_datacenter_name,
                      }
                  );

    #get vsphere hypervisor's view
    my $view_args       = {name => $self->host_hostname};
    my $hypervisor_view = $vsphere->findEntityView(
                              view_type    => 'HostSystem',
                              hash_filter  => $view_args,
                              begin_entity => $dc_view,
                          );

    if( defined($hypervisor_view->summary->hardware->memorySize) &&
        defined($hypervisor_view->summary->quickStats->overallMemoryUsage)) {

        #we convert the memory used from MB to Bytes
        my $memory_used      = 1024
                               * 1024
                               * $hypervisor_view->summary->quickStats->overallMemoryUsage;

        my $memory_available = $hypervisor_view->summary->hardware->memorySize
                               - $memory_used;

        return {
            'mem_effectively_available'   => $memory_available,
            'mem_theoretically_available' => $memory_available,
        }
    }
    else {
        $errmsg  = 'Hypervisor\'s memory available undefined for hypervisor '. $self->host_hostname;
        $errmsg .= 'is host connected?';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }
}

=pod

=begin classdoc

Return virtual machine resources. If no resssource type(s) is(are) specified in parameters,
return all known resources.

@param vm the target vm
@param resources an array containing the desired resources

@return \%vms_ressources

=end classdoc

=cut

sub getVmResources {
    my ($self,%args) = @_;

    General::checkParams(
              args     => \%args,
              optional => { vm => undef, resources => [ 'ram', 'cpu' ] }
    );

    my $vsphere = $self->getVsphereManager();
    $vsphere->negociateConnection();

    my $view_args       = {name => $self->host_hostname};
    my $hypervisor_view = $vsphere->findEntityView(
                              view_type   => 'HostSystem',
                              hash_filter => $view_args,
                          );

    # If no vm specified, get resources for all hypervisor vms.
    my @vms;
    if (not defined $args{vm}) {
        my $vms_mo_ref = $hypervisor_view->vm;
        foreach my $vm_ref (@$vms_mo_ref) {
            my $VM = $vsphere->getView(mo_ref => $vm_ref);
            push @vms, $VM->name;
        }
    } else {
        push @vms, $args{vm};
    }

    my %resources     = map { $_ => 1 } @{ $args{resources} };
    my $vms_resources = {};

    foreach my $vm (@vms) {
        my $vm_view = $vsphere->findEntityView(
                          view_type    => 'VirtualMachine',
                          hash_filter  => {name => $vm},
                          begin_entity => $hypervisor_view,
                      );

        my $vm_resources = {};
        if (defined $resources{ram}) {
            if (defined $vm_view->summary->quickStats->hostMemoryUsage) {
                #We convert the MB returned in Bytes
                $vm_resources->{$vm}->{'ram'} =
                    1024 * 1024 * $vm_view->summary->quickStats->hostMemoryUsage;
            } else {
                $errmsg  = 'Used memory not available for vm '. $vm;
                $errmsg .= 'is the vm running?';
                $log->info($errmsg);
            }
        }
        if (defined $resources{cpu}) {
            $vm_resources->{$vm}->{'cpu'} = $vm_view->summary->config->numCpu;
        }

        $vms_resources = merge ($vms_resources,$vm_resources);
    }

    return $vms_resources;
}

1;
