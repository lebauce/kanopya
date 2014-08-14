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

=pod
=begin classdoc

Stop the host corresponding to the node to release.

@since    2012-Aug-20
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::EOperation::EReleaseNode;
use base EEntity::EOperation;

use Kanopya::Exceptions;


use strict;
use warnings;

use TryCatch;
use Log::Log4perl "get_logger";
use Data::Dumper;

my $log = get_logger("");


=pod
=begin classdoc

@param node the node to release

=end classdoc
=cut

sub check {
    my $self = shift;
    my %args = @_;

    General::checkParams(args     => $self->{context},
                         required => [ "deployment_manager", "node", "boot_manager" ]);
}


=pod
=begin classdoc

Stop the host, set the node a as 'goingout'.

=end classdoc
=cut

sub execute {
    my $self = shift;

    $self->{context}->{deployment_manager}->releaseNode(
        node         => $self->{context}->{node},
        boot_manager => $self->{context}->{boot_manager},
        %{ $self->{params} }
    );
}


=pod
=begin classdoc

Wait for the host shutdown properly.

=end classdoc
=cut

sub postrequisites {
    my ($self, %args) = @_;

    $self->{context}->{deployment_manager}->checkNodeDown(
        node => $self->{context}->{node},
        %{ $self->{params} }
    );
}


=pod
=begin classdoc

Removing objects from the context

=end classdoc
=cut

sub finish {
    my ($self, %args) = @_;

    delete $self->{context}->{deployment_manager};
    delete $self->{context}->{boot_manager};
    delete $self->{context}->{node};
}

1;
