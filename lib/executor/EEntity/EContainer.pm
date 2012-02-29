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

    my $executor_context = $args{econtext};

    # Instanciate source manager and context
    my $source_container = $self;
    my $source_provider  = $source_container->_getEntity->getServiceProvider;
    my $source_manager   = EFactory::newEEntity(
                               data => $source_provider->getDefaultManager(
                                           category => 'ExportManager'
                                       )
                           );

    $source_manager->{econtext} = EFactory::newEContext(
                                      ip_source      => $executor_context->getLocalIp,
                                      ip_destination => $source_provider->getMasterNodeIp,
                                  );

    # Instanciate destination manager and context
    my $dest_container = $args{dest};
    my $dest_provider  = $source_container->_getEntity->getServiceProvider;
    my $dest_manager   = EFactory::newEEntity(
                             data => $dest_provider->getDefaultManager(
                                         category => 'ExportManager'
                                     )
                         );

    $dest_manager->{econtext} = EFactory::newEContext(
                                    ip_source      => $executor_context->getLocalIp,
                                    ip_destination => $dest_provider->getMasterNodeIp,
                                );

    # Temporary export the containers to copy contents
    my $source_access = EFactory::newEEntity(data =>
                            $source_manager->createExport(
                                container   => $source_container->_getEntity,
                                export_name => $source_container->_getEntity->getAttr(
                                                   name => 'container_name'
                                               ),
                                econtext    => $source_manager->{econtext},
                                erollback   => $args{erollback}
                            )
                        );

    my $dest_access = EFactory::newEEntity(
                          data => $dest_manager->createExport(
                              container   => $dest_container->_getEntity,
                              export_name => $dest_container->_getEntity->getAttr(
                                                 name => 'container_name'
                                             ),
                              econtext    => $dest_manager->{econtext},
                              erollback   => $args{erollback}
                          )
                      );

    # Copy contents with container accesses specific protocols
    $source_access->copy(dest => $dest_access,
                          econtext  => $args{econtext},
                          erollback => $args{erollback});

    # Remove temporary exports
    $source_manager->removeExport(container_access => $source_access->_getEntity,
                                  econtext         => $source_manager->{econtext},
                                  erollback        => $args{erollback});

    $dest_manager->removeExport(container_access => $dest_access->_getEntity,
                                econtext         => $dest_manager->{econtext},
                                erollback        => $args{erollback});
}

=head2 resize

=cut

sub resize {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'size', 'econtext' ]);
}

1;

__END__

=head1 AUTHOR

Copyright (c) 2012 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
