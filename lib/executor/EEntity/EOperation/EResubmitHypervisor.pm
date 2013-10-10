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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package EEntity::EOperation::EResubmitHypervisor;
use base "EEntity::EOperation";

use strict;
use warnings;
use Entity;
use CapacityManagement;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub check {
    my $self = shift;

    General::checkParams(args => $self->{context}, required => [ "host" ]);

    $self->{context}->{cloud_manager} = EEntity->new(
                                            data => $self->{context}->{host}->getCloudManager(),
                                        );
}


sub execute {
    my $self = shift;
    $self->SUPER::execute();

    if (not $self->{context}->{host}->isa('EEntity::EHost::EHypervisor')) {
        my $error = 'Operation can only be applied to an hypervisor';
        throw Kanopya::Exception(error => $error);
    }

    my $cm = CapacityManagement->new(cloud_manager => $self->{context}->{cloud_manager});

    my $resubmition_hv_ids = $cm->resubmitHypervisor(hv_id => $self->{context}->{host}->id);

    while (my ($vm_id, $hv_id) = each %{ $resubmition_hv_ids }) {
        $self->workflow->enqueueNow(workflow => {
             name   => 'ResubmitNode',
             params => {
                 context => {
                     host        => Entity->get(id => $vm_id),
                     hypervisor  => Entity->get(id => $hv_id),
                 }
             }
        });
    }
}

sub finish {
    my ($self) = @_;
    $self->SUPER::finish();

    delete $self->{context}->{host};
}

sub cancel {
    my $self = shift;

    $self->SUPER::cancel();
}
1;
