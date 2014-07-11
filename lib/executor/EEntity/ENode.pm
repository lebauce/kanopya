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

use TryCatch;
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
        $log->debug("Checking availability of component: " . $component->label);

        if (! $component->isUp(node => $self)) {
            $log->info("Component <" . $component->label . "> not yet operational " .
                       "on node <" . $self->label .  ">");
            return 0;
        }
    }
    return 1;
}


=pod
=begin classdoc

Check if the components installed on this node are properly configured.

=end classdoc
=cut

sub checkConfiguration {
    my ($self, %args) = @_;

    try {
        my $agent = $self->getComponent(category => "Configurationagent");
        return EEntity->new(entity => $agent)->isConfigured(node => $self);
    }
    catch {
        $log->warn("Unable to find any configuration agent on the node, " .
                   "skipping deployment configuration !")
    }
    return 1;
}


sub getEContext {
    my $self = shift;

    return $self->SUPER::getEContext(dst_ip => $self->adminIp);
}


1;
