#    Copyright © 2011 Hedera Technology SAS
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

package EEntity::EComponent::ELvm2::ELvm2Mock;
use base "EEntity::EComponent::ELvm2";

use strict;
use warnings;

use General;
use Kanopya::Exceptions;

use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;


sub lvCreate{
    my $self = shift;
    my %args = @_;
    
    General::checkParams(args     => \%args,
                         required => [ "lvm2_lv_name", "lvm2_lv_size",
                                       "lvm2_lv_filesystem", "vg_name" ]);

    $log->info("Mock: doing nothing instead of lvm2 logical volume <$args{vg_name}/$args{lvm2_lv_name}> creation.");
}

sub mkfs {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "device", "fstype" ]);

    $log->info("Mock: doing nothing instead of mkfs device <$args{device}> in <$args{fstype}>.");
}

1;
