#    Copyright © 2012 Hedera Technology SAS                                                                                                                                                                       
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

package VsphereProvider;

use strict;
use warnings;
use Data::Dumper;
use Entity::Host::Hypervisor::Vsphere5Hypervisor;
use Vsphere5Datacenter;

sub new {
    my ($class,%args) = @_;

    my $self = {};
    bless $self, $class;

    $self->{host} = $args{host};

    return $self;
}

=head2 retrieveData

    Desc: query vsphere API to retrieve vms or hypervisors datas
    Args:

=cut

sub retrieveData {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['var_map']);

    my $host_type        = $self->{host}->getHostType();
    my $service_provider = $self->{host}->getServiceProvider();
    my $vsphere;
    my $values;
    my $time;

    if ($host_type eq 'Virtual Machine') {
        $vsphere = $service_provider->getManager(manager_type => 'host_manager');
        $values  = $self->_retrieveVmData(var_map => $args{var_map}, vsphere => $vsphere);
        $time    = time();
    }
    elsif ($host_type eq 'Host') {
        $vsphere = $service_provider->getComponent(
                       name    => 'vsphere',
                       version => 5
        );
        $values  = $self->_retrieveHypervisorData(var_map => $args{var_map}, vsphere => $vsphere);
        $time    = time();
    }

    return ($time, $values);
}

=head2 _retrieveVmData

    Desc: Get data from a vsphere VM 
    Args: $host, $var_map

=cut

sub _retrieveVmData {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['var_map', 'vsphere']);


    #get vm's host
    my $hypervisor = Entity::Host::Hypervisor::Vsphere5Hypervisor->find(hash => { 
                         hypervisor_id => $self->{host}->hypervisor_id });

    #get hypervisor datacenter
    my $datacenter = Vsphere5Datacenter->find(hash => {
                         vsphere5_datacenter_id => $hypervisor->vsphere5_datacenter_id });

    #get vsphere hypervisor's datacenter view
    my $dc_view = $args{vsphere}->findEntityView(
                      view_type   => 'Datacenter',
                      hash_filter => {
                          name => $datacenter->vsphere5_datacenter_name
                      });

    #get vsphere hypervisor view
    my $hv_view = $args{vsphere}->findEntityView(
                      view_type    => 'HostSystem',
                      hash_filter  => {
                            name => $hypervisor->host_hostname
                      },
                      begin_entity => $dc_view,
                  );

    #get the VM view from vsphere
    my $vm_view = $args{vsphere}->findEntityView(
                      view_type    => 'VirtualMachine',
                      hash_filter  => {
                          name => $self->{host}->host_hostname
                      },
                      begin_entity => $hv_view,
                   );

    #finally retrieve the data
    my %values;
    foreach my $oid ( @{ $args{var_map} }) {
        my $value = $vm_view;
        for my $selector (split(/\./,$oid)) {
            $value = $value->$selector;
        }
        $values{$oid} = $value;
    }

    return \%values;
}

=head2 _retrieveHypervisorData

    Desc: Get data from a vsphere hypervisor 
    Args: $host, $var_map

=cut

sub _retrieveHypervisorData {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['var_map','vsphere']);


}

1;
