# EContext.pm - Abstract Class for EContext Classes 

#    Copyright © 2011-2012 Hedera Technology SAS
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
# Created 14 july 2010

=head1 NAME

EContext : Abstract class for EContext Classes

=cut

package EContext;

use strict;
use warnings;

our $VERSION = "1.00";

=head2 new

Keep the source ip whatever the concrete type of EContext.

=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ 'local' ],
                                         optional => { timeout => 30 });

    my $self = {
        local_ip => $args{local},
        timeout  => $args{timeout}
    };

    bless $self, $class;
    return $self;
}

sub getLocalIp {
    my ($self) = @_;
    return $self->{local_ip};
}

=head2 execute

execute(command => $command)
This method must be implemented in child classes

=cut

sub execute {}

=head2 send

send(src => $srcfullpath, dest => $destfullpath)
This method must be implemented in child classes

=cut

sub send {}

1;
