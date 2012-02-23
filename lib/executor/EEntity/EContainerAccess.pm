#    Copyright 2011 Hedera Technology SAS
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

=head1 NAME

EContainerAccess - Abstract class of Container object

=head1 SYNOPSIS



=head1 DESCRIPTION

EContainerAccess is an abstract class of Container objects

=head1 METHODS

=cut

package EEntity::EContainerAccess;
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


=head2 mount

    desc: Abstract method. Mount the container with
          the protocol defined by the container access.

=cut

sub mount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    throw Kanopya::Exception::NotImplemented();
}

=head2 mount

    desc: Abstract method. Umount the container.

=cut

sub umount {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ 'mountpoint', 'econtext' ]);

    throw Kanopya::Exception::NotImplemented();
}


1;

__END__

=head1 AUTHOR

Copyright (c) 2010 by Hedera Technology Dev Team (dev@hederatech.com). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
