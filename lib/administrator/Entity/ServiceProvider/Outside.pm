# Entity::ServiceProvider::Outside.pm  

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

Entity::ServiceProvider::Outside

=head1 SYNOPSIS

=head1 DESCRIPTION

blablabla

=cut

package Entity::ServiceProvider::Outside;
use base "Entity::ServiceProvider";

use constant ATTR_DEF => {};

sub getAttrDef { return ATTR_DEF; }

=head2 addConnector

link an existing connector with the outside service provider

=cut

sub addConnector {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => ['connector']);

    my $connector = $args{connector};
    $connector->setAttr(name => 'outside_id', value => $self->getAttr(name => 'outside_id'));
    $connector->save();

    return $connector->{_dbix}->id;
}

1;
