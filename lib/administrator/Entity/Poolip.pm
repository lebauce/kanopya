# Entity::Poolip.pm  

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
# Created 16 july 2010

=head1 NAME

Entity::Poolip

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::Poolip;
use base "Entity";

use constant ATTR_DEF => {
	poolip_name			=> { pattern      => '.*',
							 is_mandatory => 1,
                           },
    poolip_desc			=> { pattern      => '.*',
							 is_mandatory => 0,
                           },
    poolip_addr			=> { pattern      => '.*',
							 is_mandatory => 1,
                           },
    poolip_mask			=> { pattern      => '\d+',
							 is_mandatory => 1,
                           },
    poolip_netmask		=> { pattern      => '.*',
							 is_mandatory => 1,
                           },
    poolip_gateway		=> { pattern      => '.*',
							 is_mandatory => 1,
                           },                           
};

sub getAttrDef { return ATTR_DEF; }
sub getPoolips {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['hash']);

    return $class->search(%args);
}
sub toString {
    my $self = shift;
    my $string = $self->{_dbix}->get_column('poolip_name');
    return $string;
}
1;
