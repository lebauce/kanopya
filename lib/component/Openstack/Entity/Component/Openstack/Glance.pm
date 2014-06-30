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

package  Entity::Component::Openstack::Glance;
use base "Entity::Component";

use strict;
use warnings;

use Hash::Merge qw(merge);
use Log::Log4perl "get_logger";
my $log = get_logger("");

use constant ATTR_DEF => {
    mysql5_id => {
        label        => 'Database server',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
    nova_controller_id => {
        label        => 'Openstack controller',
        type         => 'relation',
        relation     => 'single',
        pattern      => '^\d*$',
        is_mandatory => 0,
        is_editable  => 1,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getNetConf {
    return {
        glance_registry => {
            port => 9191,
            protocols => ['tcp']
        },
        image_api => {
            port => 9292,
            protocols => ['tcp']
        }
    };
}

sub getPuppetDefinition {
    my ($self, %args) = @_;
    my $definition = $self->SUPER::getPuppetDefinition(%args);

    if (ref($self->mysql5) ne 'Entity::Component::Mysql5') {
        throw Kanopya::Exception::Internal(
            error => "Only mysql is currently supported as DB backend"
        );
    }

    my $name = "glance-" . $self->id; 
    return merge($self->SUPER::getPuppetDefinition(%args), {
        glance => {
            classes => {
                'kanopya::openstack::glance' => {
                    email => $self->getMasterNode->owner->user_email,
                    database_user => $name,
                    database_name => $name
                }
            },
            dependencies => $self->getDependentComponents()
        }
    });
}


=pod
=begin classdoc

Glance depend on the keystone of the nova controller and its mysql.

=end classdoc
=cut

sub getDependentComponents {
    my ($self, %args) = @_;

    return [ $self->nova_controller->keystone, $self->mysql5 ];
}


sub checkConfiguration {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, optional => { 'ignore' => [] });

    for my $attr ("mysql5", "nova_controller") {
        $self->checkAttribute(attribute => $attr);
    }

    $self->SUPER::checkConfiguration(ignore => $args{ignore});
}

1;
