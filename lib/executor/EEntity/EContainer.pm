# Copyright 2012 Hedera Technology SAS
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

package EEntity::EContainer;
use base "EEntity";

use strict;
use warnings;

use General;
use EFactory;

use Kanopya::Exceptions;

use Log::Log4perl "get_logger";

my $log = get_logger("executor");
my $errmsg;

our $VERSION = '1.00';


=head2 copy

=cut

sub copy {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'dest', 'econtext' ]);

    my $source_size = $self->getAttr(name => 'container_size');
    my $dest_size   = $args{dest}->getAttr(name => 'container_size');

    # Check if the destination container is not to small.
    if ($dest_size < $source_size) {
        throw Kanopya::Exception::Execution(
                  error => "Source container <$source_size> is larger than the dest container <$dest_size>."
              );
    }

    # TODO: copy locally without exporting caontiners if they are
    #       provided by the same disk manager.

    # TODO: use an existing export if exist, and is shared.

    # Get a container access for this container via default method.
    my $source_access = $self->createDefaultExport(erollback => $args{erollback});
    my $dest_access = $args{dest}->createDefaultExport(erollback => $args{erollback});

    # Copy contents with container accesses specific protocols
    $source_access->copy(dest      => $dest_access,
                         econtext  => $args{econtext},
                         erollback => $args{erollback});

    # Remove temporary default exports
    $self->removeDefaultExport(container_access => $source_access,
                               erollback        => $args{erollback});

    $args{dest}->removeDefaultExport(container_access => $dest_access,
                                     erollback        => $args{erollback});
}

=head2 createDefaultExport

=cut

sub createDefaultExport {
    my $self = shift;
    my %args = @_;

    my $export_manager = EFactory::newEEntity(data => $self->getDefaultExportManager());

    # Temporary export the containers to copy contents
    my $container_access = $export_manager->createExport(
                               container   => $self,
                               export_name => $self->getAttr(name => 'container_name'),
                               erollback   => $args{erollback}
                           );

    return $container_access;
}

=head2 removeDefaultExport

=cut

sub removeDefaultExport {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'container_access' ]);

    my $export_manager = EFactory::newEEntity(data => $self->getDefaultExportManager());

    $export_manager->removeExport(container_access => $args{container_access},
                                  erollback        => $args{erollback});

}

sub getDefaultExportManager {
    my $self = shift;
    my %args = @_;

    throw Kanopya::Exception::NotImplemented();
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
