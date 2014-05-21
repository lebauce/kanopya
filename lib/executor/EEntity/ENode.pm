# Copyright © 2011-2012 Hedera Technology SAS
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

ENode is the execution class of node entities

@since    2014-Apr-14
@instance hash
@self     $self

=end classdoc
=cut

package EEntity::ENode;
use base EEntity;

use strict;
use warnings;

use Log::Log4perl "get_logger";

my $log = get_logger("");


=pod
=begin classdoc

Check the availability of the components installer on this node

=end classdoc
=cut

sub checkComponents {
    my ($self, %args) = @_;

    my @components = sort { $a->priority <=> $b->priority } $self->components;
    foreach my $component (map { EEntity->new(entity => $_) } @components) {
        $log->debug("Browsing component: " . $component->label);

        if (not $component->isUp(host => EEntity->new(entity => $self->host))) {
            $log->info("Component <" . $component->label . "> not yet operational " .
                       "on node <" . $self->label .  ">");
            return 0;
        }
    }
    return 1;
}


sub getEContext {
    my $self = shift;

    return EEntity->new(entity => $self->host)->getEContext();
}


1;
