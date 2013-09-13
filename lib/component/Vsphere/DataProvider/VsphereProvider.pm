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

query vsphere API to retrieve vms or hypervisors datas

@param var_map

=end classdoc
=cut


sub retrieveData {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['var_map']);

    my @oid_list = values (%{ $args{var_map} });
    my $service_provider;
    my $vsphere;
    my $results;
    my $time;

    if ($self->{host}->isa("Entity::Host::VirtualMachine::Vsphere5Vm")) {
        $vsphere = $self->{host}->getHostManager();
        $results  = $self->_retrieveVmData(oid_list => \@oid_list, vsphere => $vsphere);
        $time    = time();
    }
    elsif ($self->{host}->isa("Entity::Host::Hypervisor::Vsphere5Hypervisor")) {
        $service_provider = $self->{host}->getCluster();
        $vsphere = $service_provider->getComponent(
                       name    => 'Vsphere',
                       version => 5
        );
        $results  = $self->_retrieveHypervisorData(oid_list => \@oid_list, vsphere => $vsphere);
        $time    = time();
    }
    else {
        $errmsg = ref ($self->{host}) .' is not a valid host type for this data provider';
        throw Kanopya::Exception::Internal(error => $errmsg);
    }

    my %values = (); 
    while ( my ($name, $oid) = each %{ $args{var_map} } ) {
        $values{$name} = $results->{$oid};
    }

    return ($time, \%values);
}

=pod
=begin classdoc

Get data from a vsphere VM

@param vsphere Entity::Component::Virtualization::Vsphere5 instance

@param oid_list array of String of oid to retrieve

@return hash ref {oid => value}

=end classdoc
=cut

sub _retrieveVmData {
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => ['oid_list', 'vsphere']);


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
                   )->summary;

    #finally retrieve the data
    my %values;
    foreach my $oid ( @{ $args{oid_list} }) {
        my $value = $vm_view;
        for my $selector (split(/\./,$oid)) {
            $value = $value->$selector;
        }
        $values{$oid} = $value;
    }

    return \%values;
}


=pod
=begin classdoc

Get data from a vsphere hypervisor

@param vsphere Entity::Component::Virtualization::Vsphere5 instance

@param oid_list array of String of oid to retrieve

@return hash ref {oid => value}

=end classdoc
=cut

sub _retrieveHypervisorData {
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
                            name => $self->{host}->node->node_hostname
                      },
                      begin_entity => $dc_view,
                  )->summary;

    #finally retrieve the data
    my %values;
    foreach my $oid ( @{ $args{oid_list} }) {
        my $value = $hv_view;
        for my $selector (split(/\./,$oid)) {
            $value = $value->$selector;
        }
        $values{$oid} = $value;
    }

    return \%values;
}

1;
