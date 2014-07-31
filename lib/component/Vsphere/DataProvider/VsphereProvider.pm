#    Copyright © 2012 Hedera Technology SAS
#
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


=pod
=begin classdoc

Retrieve monitoring data through VMware vSphere software.

=end classdoc
=cut

package DataProvider::VsphereProvider;
use base DataProvider;

use strict;
use warnings;

use Kanopya::Exceptions;
use Entity::Host::Hypervisor::Vsphere5Hypervisor;
use Vsphere5Datacenter;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $errmsg;
my $log = get_logger("");

sub new {
    my ($class,%args) = @_;

    my $self = {};
    bless $self, $class;

    $self->{host} = $args{host};

    return $self;
}

=pod
=begin classdoc

Query vSphere API to retrieve VMs or hypervisors data.
If you ask the wrong type of value (e.g. you ask a hypervisor about VM data or vice versa),
this will throw an exception.

@param var_map

=end classdoc
=cut


sub retrieveData {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['var_map']);

    my $expected_prefix; # must be regexp-safe
    my $view;
    my %name_value;
    
    # First level of the OID must be either "vsphere_vm" or "vsphere_hv". OIDs must be unique!
    # TODO: add database uniqueness constraint
    
    if ($self->{host}->isa("Entity::Host::VirtualMachine::Vsphere5Vm")) {
        $expected_prefix = 'vsphere_vm';
    }
    elsif ($self->{host}->isa("Entity::Host::Hypervisor::Vsphere5Hypervisor")) {
        $expected_prefix = 'vsphere_hv';
    }
    else {
        $errmsg = ref ($self->{host}) .' is not a valid host type for this data provider';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }   
    
    {
        my @wrong_oids = ();
        foreach my $oid (values %{ $args{var_map} }) {
            if ($oid !~ /^$expected_prefix\./) {
                push @wrong_oids, $oid; 
            }
        }
        if (@wrong_oids > 0) {
            $errmsg = ref ($self->{host}) 
                . ' was asked for the following OIDs for which it is not a data provider: '
                . join(', ', @wrong_oids);
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    }       

    {
        my $vsphere;

        if ($expected_prefix eq 'vsphere_vm') {
            # $vsphere = $self->{host}->getHostManager();
            $vsphere = $self->{host}->host_manager;
            $view    = $self->_getVmView(vsphere => $vsphere);
        } else {
            # my $service_provider = $self->{host}->getCluster();
            $vsphere = $self->{host}->node->getComponent(
                           name    => 'Vsphere',
                           version => 5
            );
            $view    = $self->_getHypervisorView(vsphere => $vsphere);
        }
    }

    while ( my ($name, $oid) = each %{ $args{var_map} } ) {
        if ($oid =~ /^$expected_prefix\.(.*)$/) {
            my $real_oid = $1;
            my $value = $view;
            for my $selector (split(/\./, $real_oid)) {
                $value = $value->$selector;
            }
            $name_value{$name} = $value;
        } else {
            $errmsg = "Internal logic error: at this point, we should not have any OID"
                . " that does not start with '$expected_prefix': found '$oid'";
            throw Kanopya::Exception::Internal(error => $errmsg);
        }
    }        

    return (time(), \%name_value);
}

=pod
=begin classdoc

Get the "VirtualMachine" data object from a vSphere VM.
See http://pubs.vmware.com/vsphere-55/topic/com.vmware.wssdk.apiref.doc/vim.VirtualMachine.html

@param vsphere Entity::Component::Virtualization::Vsphere5 instance

@return The "VirtualMachine" object

=end classdoc
=cut

sub _getVmView {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['vsphere']);

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
                            name => $hypervisor->node->node_hostname
                      },
                      begin_entity => $dc_view,
                  );

    #get the VM view from vsphere
    my $vm_view = $args{vsphere}->findEntityView(
                      view_type    => 'VirtualMachine',
                      hash_filter  => {
                          name => $self->{host}->node->node_hostname
                      },
                      begin_entity => $hv_view,
                   );

    return $vm_view;
}


=pod
=begin classdoc

Get the "HostSystem" data object for a vSphere hypervisor.
See http://pubs.vmware.com/vsphere-55/topic/com.vmware.wssdk.apiref.doc/vim.HostSystem.html

@param vsphere Entity::Component::Virtualization::Vsphere5 instance

@return The "HostSystem" object

=end classdoc
=cut

sub _getHypervisorView {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['oid_list','vsphere']);

    #get hypervisor datacenter
    my $datacenter = Vsphere5Datacenter->find(hash => {
                         vsphere5_datacenter_id => $self->{host}->vsphere5_datacenter_id });

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
                            'hardware.systemInfo.uuid' => $self->{host}->vsphere5_uuid
                      },
                      begin_entity => $dc_view,
                  );
    
    return $hv_view;
}

1;
