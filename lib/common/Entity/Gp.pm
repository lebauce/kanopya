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
        is_editable  => 1,
	description  => 'The name of the group',
    },
    gp_desc => {
        pattern      => '.*',
        is_mandatory => 0,
        is_extended  => 0,
        is_editable  => 1,
        description  => 'The description of the group (e.g. Team, Business Unit, ...)',
    },
    gp_type => {
        pattern      => '^\w*$',
        is_mandatory => 1,
        is_extended  => 0,
        is_editable  => 0,
        description  => 'HCM offers a group management for all types of entities managed by the system.',
    },
};

sub getAttrDef { return ATTR_DEF; }


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

=pod
=begin classdoc

remove an entity object from the groups

@param entity : Entity::* object : an Entity object contained by the groups

=end classdoc
=cut

sub removeEntity {
    my ($self, %args) = @_;
    General::checkParams(args => \%args, required => ['entity']);

    my $entity_id = $args{entity}->{_dbix}->id;
    $self->{_dbix}->ingroups->find({entity_id => $entity_id})->delete();
}


=pod
=begin classdoc

Return a string representation of the entity

@return string representation of the entity

=end classdoc
=cut

sub toString {
    my ($self) = @_;
    my $string = $self->{_dbix}->get_column('gp_name');
    return $string;
}

1;
