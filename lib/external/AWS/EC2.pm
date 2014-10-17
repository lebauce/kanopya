#    Copyright © 2014 Hedera Technology SAS
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

Implement AWS EC2 (Compute) operations

=end classdoc
=cut

package AWS::EC2;

use strict;
use warnings;

use General;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");

=pod
=begin classdoc

@constructor

@param api An instance of AWS::API

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'api' ]);

    my $self = {
        api => $args{api}
    };
    bless $self, $class;

    return $self;   
}



=pod

=begin classdoc

Lists all available images

=end classdoc
=cut


sub getImages {
    my ($self, %args) = @_;
    
    my $response = $self->{api}->get(
        action => 'DescribeImages',
        params => ['Owner.1', 'self']
    );
    
    # For the moment, we also add some generic images.
    # TODO: this is not sustainable in the long run. Discuss what to do,
    # particularly when we have no "own" images.
    my $response2 = $self->{api}->get(
        action => 'DescribeImages',
        params => ['ImageId', [
            'ami-f7f03d80', # RHEL 7 
            'ami-30842747', # SLES 11 SP3
            'ami-f0b11187', # Ubuntu
            'ami-748e2903', # Amazon Linux
            'ami-d02386a7'  # Windows Server 2012 R2
        ]]
    );
    $log->debug("VHH DEBUG: first XML document is: ".$response->toString(0));
    
    my @found_images = ();
    my $xpc = $self->{api}->xpc;
    foreach my $xml ($response, $response2) {
        foreach my $item ($xpc->findnodes("//x:imagesSet/x:item", $xml)) {
            my $size_in_GB = 0;
            foreach my $volsize_item ($xpc->findnodes("x:blockDeviceMapping//x:volumeSize", $item)) {
                $size_in_GB += $volsize_item->textContent;
            }
            push @found_images, {
                image_id   => $xpc->findvalue('x:imageId', $item),
                name => $xpc->findvalue('x:name', $item),
                desc => $xpc->findvalue('x:description', $item),
                size => $size_in_GB * 1024**3
            }
        }
    }
    
    $log->debug("Found the following AWS images: ".Data::Dumper->Dump([ \@found_images ]));    
    return \@found_images;
}

=pod

=begin classdoc

Lists all VMs ("Instances").

=end classdoc
=cut

sub getInstances {
    my ($self, %args) = @_;
    
    my $response = $self->{api}->get( action => 'DescribeInstances' );
    my @found_instances = ();
    my $xpc = $self->{api}->xpc;

    foreach my $item ($xpc->findnodes('//x:instancesSet/x:item', $xml)) {
        # TODO: need to get private addresses and/or all interfaces ?
        my $first_interface = ($xpc->findnodes('x:networkInterfaceSet/x:item', $xpc))[0];
        push @found_instances, {
            instance_id => $xpc->findvalue('x:instanceId', $item),
            'state'     => $xpc->findvalue('x:instanceState/x:name', $item),
            ip          => $xpc->findvalue('x:ipAddress', $item),
            type        => $xpc->findvalue('x:instanceType', $item),
            mac_addr    => $xpc->findvalue('x:macAddress', $first_interface)
        };
    }
    
    return \@found_instances;
}


=pod

=begin classdoc

@return A hash with information about the whole infrastructure

=end classdoc
=cut

# Analogous to OpenStack::Infrastructure->load.
sub getInfrastructure {
    my ($self) = @_;

#    my $hypervisors = OpenStack::Hypervisor->detailList(%args);
#    for my $hypervisor (@$hypervisors) {
#        my $vms = OpenStack::Hypervisor->servers(%args, id => $hypervisor->{id});
#        my @vm_details = ();
#        for my $vm (@$vms) {
#            my $detail = OpenStack::Server->detail(%args, id => $vm->{uuid}, flavor_detail => 1);
#            push @vm_details, $detail->{server};
#        }
#        $hypervisor->{servers} = \@vm_details;
#    }

    return {
#        'hypervisors' => $hypervisors,
        'images'    => $self->getImages,
        'instances' => $self->getInstances
#        'volumes' => OpenStack::Volume->list(%args, all_tenants => 1),
#        'volume_types' => OpenStack::VolumeType->list(%args),
#        'tenants' => OpenStack::Tenant->list(%args, all_tenants => 1),
#        'flavors' => OpenStack::Flavor->list(%args),
#        'networks' => OpenStack::Network->list(%args),
#        'availability_zones' => OpenStack::Zone->list(%args),
#        'subnets' => OpenStack::Subnet->list(%args),
    }
}

1;