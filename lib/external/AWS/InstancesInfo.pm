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

A data holder for VM information. Can be used like a hashref, to retrieve information
for a single VM ( get() ), or like an arrayref ( arrayref() ). 

=end classdoc
=cut

# NOTE: this is quite close to an Ordered Hash, of which there are several implementations on CPAN.
package AWS::InstancesInfo;

use strict;
use warnings;

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
    my ($class) = @_;
    my $self = {
        vms => [],
        instanceId_pos => {},
        total => 0
    };
    bless $self, $class;
    return $self;   
}

=pod
=begin classdoc

Add information about a new VM to this object.
The options given in a hashref usually contain the keys "instance_id", "state", "ip", "type" and "mac_addr".

Throws an exception if there is no key "instance_id", or if its value is already
present in this object.

=end classdoc
=cut

sub add {
    my ($self, $infos) = @_;
    unless (defined $infos->{instance_id}) {
        die "The given VM infos must contain an 'instance_id' field";
    }
    my $instance_id = $infos->{instance_id};
    if (exists $self->{instanceId_pos}{$instance_id}) {
        die "The given instance ID <$instance_id> exists already in this object";
    }
    push @{$self->{vms}}, $infos;
    $self->{instanceId_pos}{$instance_id} = $self->{total};
    $self->{total} += 1;
}


=pod
=begin classdoc

Retrieve information for a single VM.
Throws an exception if not found.

@param instance_id (String)

=end classdoc
=cut

sub get {
    my ($self, $instance_id) = @_;
    my $pos = $self->{instanceId_pos}{$instance_id};
    unless (defined $pos) {
        die "The given instance ID <$instance_id> does not exist in this object";
    }
    
    return $self->{vms}[$pos];
}


=pod
=begin classdoc

Retrieve information for several VMs, all given as parameters.
Returns an arrayref with the VM information in the same order.
Throws an exception if a VM cannot be found.

=end classdoc
=cut

sub getMany {
    my ($self, @instance_ids) = @_;
    my @vm_infos = ();
    foreach my $instance_id (@instance_ids) {
        push @vm_infos, $self->get($instance_id);
    }
    return \@vm_infos;
}

=pod
=begin classdoc

Update information about a specific VM, keeping its position in the list.
If the VM does not exist in this object yet, it is added.

Same parameter as in add() - the hashref must include the key "instance_id".

=end classdoc
=cut

sub replaceOrAdd {
    my ($self, $infos) = @_;   
    unless (defined $infos->{instance_id}) {
        die "The given VM infos must contain an 'instance_id' field";
    }
    my $instance_id = $infos->{instance_id};
    my $pos = $self->{instanceId_pos}{$instance_id};
    
    if (defined $pos) {
        $self->{vms}[$pos] = $infos;
    } else {
        $self->add($infos);
    }

}

=pod
=begin classdoc

Put all information from the given object into this one
(by means of replaceOrAdd()).

=end classdoc
=cut

sub merge {
    my ($self, $other_instance) = @_;
        
    foreach my $other_vm (@{$other_instance->arrayref}) {
        $self->replaceOrAdd($other_vm);
    }
}


=pod
=begin classdoc

Return all information in a single arrayref.
The order will be the one in which additions have happened.
This is a cheap operation.

=end classdoc
=cut

sub arrayref {
    my ($self) = @_;
    return $self->{vms};
}

