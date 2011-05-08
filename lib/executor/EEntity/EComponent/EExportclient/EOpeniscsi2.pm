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
package EEntity::EComponent::EExportclient::EOpeniscsi2;

use strict;

use base "EEntity::EComponent::EExportclient";


# contructor

sub new {
    my $class = shift;
    my %args = @_;

    my $self = $class->SUPER::new( %args );
    return $self;
}

sub initiator_conf ($$) {
    my $self = shift;
    my %args = @_;

    if ((! exists $args{initiatorname} or ! defined $args{initiatorname})||
        (! exists $args{econtext} or ! defined $args{econtext}) ||
        (! exists $args{remotepath} or ! defined $args{remotepath})) { 
        throw Kanopya::Exception::Internal(error => "EEntity::EExport::EOpeniscsi2->generateInitiatorConf need a initiatorname and a econtext named argument to generate initiatorname!"); }
        
        my $result = $args{econtext}->execute("echo \"InitiatorName=$args{'initiatorname'}\" > $args{remotepath}/iscsi/initiatorname.iscsi");
        return 0;
}

sub AddNode {}

1;
