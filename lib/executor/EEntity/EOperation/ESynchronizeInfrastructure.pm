# ESynchronizeInfrastructure.pm - Operation class implementing

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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 26 sept 2012

=head1 NAME

EEntity::EOperation::ESynchronizeInfrastructure - Operation class implementing

=head1 SYNOPSIS

This Object represent an operation.
It allows to implement

=head1 DESCRIPTION

Component is an abstract class of operation objects

=head1 METHODS

=cut
package EEntity::EOperation::ESynchronizeInfrastructure;
use base "EEntity::EOperation";

use strict;
use warnings;
use Entity;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;
    General::checkParams(args => $self->{context},
                         optional => {'hypervisor'    => undef,
                                      'cloud_manager' => undef,
                                      'vm'            => undef,
                         });
}

sub prepare {
    my $self = shift;
    $self->SUPER::prepare();
    if (defined $self->{context}->{hypervisor} && 
        not $self->{context}->{hypervisor}->isa('EEntity::EHost::EHypervisor')) {

        my $error = 'Operation can only be applied to an hypervisor';
        throw Kanopya::Exception(error => $error);
    }
}

sub execute {
    my $self = shift;

    if (! defined $self->{context}->{cloud_manager}) {
        $self->{context}->{cloud_manager} = EEntity->new(
                                            data => $self->{context}->{hypervisor}->getCloudManager(),
                                         );
    }

    if (! defined $self->{params}->{diff_infra_db}) {
        if (defined $self->{context}->{hypervisor}) {
            $self->{params}->{diff_infra_db} = $self->{context}->{cloud_manager}->checkHypervisorVMPlacementIntegrity(host => $self->{context}->{hypervisor});
            $self->{context}->{cloud_manager}->repairVMRessourceIntegrity(host => $self->{context}->{hypervisor});
        }
        else {
            $self->{params}->{diff_infra_db} = $self->{context}->{cloud_manager}->checkAllInfrastructureIntegrity(cloud_manager => $self->{context}->{cloud_manager});
        }

        if (defined $self->{context}->{vm}) {
            eval {
                $self->{params}->{diff_infra_db} = $self->{context}
                                                        ->{cloud_manager}
                                                        ->checkVMPlacementIntegrity(
                                                              host          => $self->{context}->{vm},
                                                              diff_infra_db => $self->{params}->{diff_infra_db},
                                                          );
            };
        }
    } 

    $self->{context}->{cloud_manager}->repairWrongHypervisor(vm_ids => $self->{params}->{diff_infra_db}->{wrong_hv});
    $self->{context}->{cloud_manager}->repairVmInDBNotInInfra(vm_ids => $self->{params}->{diff_infra_db}->{base_not_hv_infra});
    $self->{context}->{cloud_manager}->repairVmInInfraUnkInDB(vm_uuids => $self->{params}->{diff_infra_db}->{unk_vm_uuids});
    $self->{context}->{cloud_manager}->repairVmInInfraWrongHostManager(vm_ids => $self->{params}->{diff_infra_db}->{infra_not_hostmanager});



    $self->SUPER::execute();
}

sub finish {
    my ($self) = @_;
    delete $self->{context}->{hypervisor};
    delete $self->{context}->{cloud_manager};
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

