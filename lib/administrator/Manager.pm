# Copyright © 2012 Hedera Technology SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

package Manager;

use strict;
use warnings;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("administrator");
my $errmsg;

=head2 checkManagerParams

=cut

sub checkManagerParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "manager_type" ]);

    $args{manager_params} = $args{manager_params} ? $args{manager_params} : {};

    if ($args{manager_type} eq 'host_manager') {
        return $self->checkHostManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'disk_manager') {
        return $self->checkDiskManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'export_manager') {
        return $self->checkExportManagerParams(%{ $args{manager_params} });
    }
    elsif ($args{manager_type} eq 'collector_manager') {
        return $self->checkCollectorManagerParams(%{ $args{manager_params} });
    }
}

1;
