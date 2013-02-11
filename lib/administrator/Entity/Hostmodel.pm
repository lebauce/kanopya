# Hostmodel.pm - This object allows to manipulate Host model
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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.
# Created 11 aug 2010
package Entity::Hostmodel;
use base "Entity";

use strict;
use warnings;

use Kanopya::Exceptions;

use General;
use Log::Log4perl "get_logger";
my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    hostmodel_brand         => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_name          => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_chipset       => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_processor_num => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_consumption   => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_iface_num     => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_ram_slot_num  => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    hostmodel_ram_max       => { pattern => '.*', is_mandatory => 1, is_extended => 0 },
    processormodel_id              => { pattern => '\d*', is_mandatory => 0, is_extended => 0 },
};

=head2 getHostmodels

=cut

sub getHostmodels {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('hostmodel_name')." ".$self->{_dbix}->get_column('hostmodel_brand');
    return $string;
}

sub getAttrDef{
    return ATTR_DEF;
}
1;
