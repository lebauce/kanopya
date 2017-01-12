#    Copyright © 2012-2013 Hedera Technology SAS
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

TODO

=end classdoc
=cut

package EManager::EExportManager;
use base EManager;


=pod
=begin classdoc

Parent method to check prerequisites for exporting disk.
Call this method in overriden method in sub classes.

=end classdoc
=cut

sub createExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args=>\%args, required => [ 'container' ]);

    # Check if the container has no container access yet
    # For instance, we allow export when a container already exproted
    # by a local container.
    #
    # TODO: Take into account shared, read-only and export type paramters
    #       to allow multiple export when possible.
    for my $access ($args{container}->container_accesses) {
        if (not $access->isa('Entity::ContainerAccess::LocalContainerAccess')) {
            throw Kanopya::Exception::Execution::ResourceBusy(
                      error => "Can not export an already exported disk."
                  );
        }
    }
}


=pod
=begin classdoc

Remove an export

=end classdoc
=cut

sub removeExport {}


=pod
=begin classdoc

Autorize a client to this container access.
By default do nothing

=end classdoc
=cut

sub addExportClient {}


=pod
=begin classdoc

Remove access of a client to this container access.
By default do nothing

=end classdoc
=cut

sub removeExportClient {}

1;
