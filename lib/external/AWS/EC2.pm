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

use AWS::InstancesInfo;
use General;

use Data::Dumper;
use Log::Log4perl "get_logger";
my $log = get_logger("");

# A very temporary cache for instance data.
# As this is a class variable, it only works within the same Perl interpreter.
my %cacheVM = (
    'data' => undef,
    'time' => undef
);

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
    my ($self) = @_;
    
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

@param InstanceId (Arrayref) If given, only retrieve information for these Instances.
@param use_cache_if_not_older_than (Integer) Allow the retrieval of cached data,
  if this data is not older than the given number of seconds. Default: 0 (do not use cached data).
  If the cache is used, the whole stored AWS::InstancesInfo will be returned,
  - an "InstanceId" parameter will be ignored.

=end classdoc
=cut

sub getInstances {
    my ($self, %args) = @_;
    my $use_cache = $args{use_cache_if_not_older_than};
    $use_cache ||= 0;
    
    if ($use_cache > 0 and $cacheVM{time} >= time() - $use_cache) {
        $log->debug("using cached data");
        return $cacheVM{data};
        
    } else { # get fresh data
        $log->debug("doing a fresh request 'DescribeInstances'");
        my @params = ('action', 'DescribeInstances');
        if ($args{InstanceId}) {
            push @params, 'InstanceId', $args{InstanceId};
        }
        my $response = $self->{api}->get(@params);
        my $result = $self->_parseInstances($response);
        
        if ($args{InstanceId}) {
            # We have fresh data, but not for all instances.
            # Let's replace only the obsolete data.
            if (defined $cacheVM{data}) {
                $cacheVM{data}->merge($result);
            }
            # We keep the 'time' as it is - there might be older data left.
        } else {
            $cacheVM{data}   = $result;
            $cacheVM{'time'} = time();
        }
        
        return $result;
    }
}

=pod

=begin classdoc

Convert XML data about one or more instances into an array of "VM information hashes".

@param xml (direct parameter - String) The XML to convert.
@return An AWS::InstancesInfo object.

=end classdoc
=cut

sub _parseInstances {
    my ($self, $xml) = @_;
    
    my $vm_infos = AWS::InstancesInfo->new();
    my $xpc = $self->{api}->xpc;

    foreach my $item ($xpc->findnodes('//x:instancesSet/x:item', $xml)) {
        # Terminated VMs may still show up for 10-20 minutes. We ignore them.
        # Terminated or shutting-down instancces do not have any network interfaces listed.
        my $state = $xpc->findvalue('x:instanceState/x:name', $item);
        next if $state eq 'terminated';
        
        # TODO: need to get private addresses and/or all interfaces ?
        my $first_interface = ($xpc->findnodes('x:networkInterfaceSet/x:item', $item))[0];
        
        my $ip = undef;
        {
            my $ip_node = $xpc->findnodes('x:ipAddress', $item);
            if ($ip_node->size > 0) {
                $ip = $ip_node->to_literal;
            }
        }
        
        $vm_infos->add({
            instance_id => $xpc->findvalue('x:instanceId', $item),
            'state'     => $state,
            ip          => $ip,   # might still be undef
            type        => $xpc->findvalue('x:instanceType', $item),
            mac_addr    => $xpc->findvalue('x:macAddress', $first_interface)
        });
    }
    
    return $vm_infos;
}


=pod

=begin classdoc

Create one or more VMs.

=end classdoc
=cut

# TODO: separate between creating new instances and starting stopped instances!
sub createInstance {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'ImageId', 'InstanceType' ]);
    
    # TODO: consider the case where we burst one existing VM ?
    my $response = $self->{api}->get(
        action => 'RunInstances',
        params => [
            'ImageId',         $args{ImageId},
            'MinCount',        1,
            'MaxCount',        1, # TODO: can we access the scalability policy here ?
            'KeyName',         'aws-test-key', # TODO: include this - where ?
            'SecurityGroupId', ['sg-cf6edfaa'], # TODO: include this - where ?
            'InstanceType',    $args{InstanceType}
        ]
    );
    
    $log->debug("VHH DEBUG: after call to createInstance: \n$response");
    
    return $self->_parseInstances($response);
}


=pod

=begin classdoc

Stop one or more VMs. They are not destroyed, they can be started again.

@param InstanceId (Arrayref of Strings) One or more instances to stop.

@return An arrayref of errors. Empty if all is OK.

=end classdoc
=cut

sub stopInstance {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'InstanceId' ]);
    
    my $response = $self->{api}->get(
        action => 'StopInstances',
        params => [ 'InstanceId', $args{InstanceId} ]
    );
    
    return $self->{api}->findErrors($response);
}


=pod

=begin classdoc

Terminate one or more VMs. Their volumes will be destroyed.

@param InstanceId (Arrayref of Strings) One or more instances to stop.

@return An arrayref of errors. Empty if all is OK.

=end classdoc
=cut

sub terminateInstance {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => [ 'InstanceId' ]);
    
    my $response = $self->{api}->get(
        action => 'TerminateInstances',
        params => [ 'InstanceId', $args{InstanceId} ]
    );
    
    return $self->{api}->findErrors($response);
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