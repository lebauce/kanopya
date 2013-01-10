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

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Manager::ExportManager;
use base "Manager";

use strict;
use warnings;

use Entity::Operation;
use Kanopya::Exceptions;

use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");
my $errmsg;

sub exportType {
    return '';
}

=head2 checkExportManagerParams

=cut

sub checkExportManagerParams {}


=pod

=begin classdoc

@return the managers parameters as an attribute definition. 

=end classdoc

=cut

sub getExportManagerParams {
    my $self = shift;
    my %args  = @_;

    return {};
}

=head2 getReadOnlyParameter

=cut

sub getReadOnlyParameter {
    throw Kanopya::Exception::NotImplemented();
}

=head2 getReadOnlyParameter

=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => \%args,
                         required => [ "container", "export_name" ]);

    $log->debug("New Operation CreateExport with attrs : " . %args);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'CreateExport',
        params   => {
            context => {
                export_manager => $self,
                container      => $args{container},
            },
            manager_params => {
                export_name => $args{export_name},
            },
        },
    );
}

=head2 removeExport

    Desc : Implement createExport from ExportManager interface.
           This function enqueue a ERemoveExport operation.
    args : export_name

=cut

sub removeExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "container_access" ]);

    $log->debug("New Operation RemoveExport with attrs : " . %args);
    Entity::Operation->enqueue(
        priority => 200,
        type     => 'RemoveExport',
        params   => {
            context => {
                container_access => $args{container_access},
            }
        },
    );
}

1;
