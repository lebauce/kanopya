#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EComponent::EIscsitarget1::EIscsitarget1Mock;
use base "EEntity::EComponent::EIscsitarget1";

use warnings;
use strict;

use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

sub gettid {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    $log->info("Mock: returning hard coded target id <1>.");
    return 1;
}

sub addTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    $log->info("Mock: doing nothing instead of iscsi target <$args{target_name}> creation.");
}

sub addLun {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args     => \%args,
                         required => [ "device", "number", "typeio",
                                       "iomode", "target_name" ]);

    $log->info("Mock: doing nothing instead of iscsi lun <$args{target_name}-lun-$args{number}> creation.");
}

sub removeTarget {
    my $self = shift;
    my %args  = @_;

    General::checkParams(args => \%args, required => [ 'target_name' ]);

    $log->info("Mock: doing nothing instead of iscsi target <$args{target_name}> deletion.");
}

1;
