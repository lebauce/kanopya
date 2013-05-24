#    Copyright © 2011-2013 Hedera Technology SAS
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

package EEntity::EOperation::ELaunchOptimiaasWorkflow;
use base EEntity::EOperation;

use strict;
use warnings;

use Kanopya::Exceptions;
use CapacityManagement;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;


sub prerequisites {
    my $self = shift;
    General::checkParams(args => $self->{context}, required => [ "cloudmanager_comp" ]);

    my $diff_infra_db = $self->{context}
                        ->{cloudmanager_comp}
                        ->checkAllInfrastructureIntegrity();

    if (! $self->{context}->{cloudmanager_comp}->isInfrastructureSynchronized(hash => $diff_infra_db)) {

        $self->workflow->enqueueBefore(
            operation => {
                priority => 200,
                type     => 'SynchronizeInfrastructure',
                params   => {
                    context => {
                        cloud_manager => $self->{context}->{cloudmanager_comp}
                    },
                diff_infra_db => $diff_infra_db,
                }
            }
        );
        return -1;
    }

}

sub execute{
    my $self = shift;
    $self->SUPER::execute();

    my $cm  = CapacityManagement->new(cloud_manager => $self->{context}->{cloudmanager_comp});

    my $operation_plan = $cm->optimIaas();

    for my $operation (@$operation_plan){
        $log->info('Operation enqueuing');
        $self->workflow->enqueue(
            %$operation
        );
    }
}

1;
