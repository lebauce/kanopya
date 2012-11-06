#    Copyright © 2012 Hedera Technology SAS
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
package Entity::Combination::ConstantCombination;

use strict;
use warnings;
use base 'Entity::Combination';
use Entity::Indicator;
use Data::Dumper;
# logger
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    service_provider_id =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    value =>  {pattern       => '^((id\d+)|[ .+*()-/]|\d)+$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1,
    }
};

sub getAttrDef { return ATTR_DEF; }

sub getAttr {
    my $self = shift;
    my %args = @_;
    return $self->SUPER::getAttr(%args);
}

# Virtual attribute getter
sub label {
    my $self = shift;
    return $self->value;
}

sub computeValueFromMonitoredValues {
    my $self = shift;
    return $self->value;
}

sub computeLastValue {
    my $self = shift;
    return $self->value;
}

sub getDependantIndicatorIds {
    my $self = shift;
    return ();
}

sub deleteIfConstant {
    my $self = shift;
    return $self->delete();
}

sub toString {
    my $self = shift;
    return $self->value;
};
1;
