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

# Maintained by Dev Team of Hedera Technology <dev@hederatech.com>.

=pod

=begin classdoc

TODO

=end classdoc

=cut

package Entity::Gp;
use base "Entity";

use strict;
use warnings;
use Kanopya::Exceptions;
use Administrator;
use General;
use Data::Dumper;
use Log::Log4perl "get_logger";

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    gp_name => {
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 1
    },
    gp_desc => {
        pattern      => '^[\w\s]*$',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 1
    },
    gp_type => {
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

=head2 getSize

    Class : public
    Desc  : return the number of entities in this group
    return : scalar (int)

=cut

sub getSize {
    my ($self) = @_;
    return $self->{_dbix}->ingroups->count();
}


=pod

=begin classdoc

Add an entity in a this group. Do not throw exception if entity
already in the group, but warn the error as , it should not be occurs.

@param entity the entity to add in the group

=end classdoc

=cut


sub appendEntity {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => ['entity']);

    eval {
        $self->{_dbix}->ingroups->create({
            gp_id     => $self->id,
            entity_id => $args{entity}->id
        });
    };
    if ($@) {
        $log->warn("$args{entity} seems already in group $self: $@");
    }
}

=head2 removeEntity

    Class : Public

    Desc : remove an entity object from the groups

    args:
        entity : Entity::* object : an Entity object contained by the groups

=cut

sub removeEntity {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['entity']);

    my $entity_id = $args{entity}->{_dbix}->id;
    $self->{_dbix}->ingroups->find({entity_id => $entity_id})->delete();
}

=head2 toString

    desc: return a string representation of the entity

=cut

sub toString {
    my ($self) = @_;
    my $string = $self->{_dbix}->get_column('gp_name');
    return $string;
}

1;
