# Copyright © 2011-2013 Hedera Technology SAS
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

package ServiceProviderManager;
use base 'BaseDB';

use strict;
use warnings;

use ParamPreset;
use Entity::Component;

use Hash::Merge;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    service_provider_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_delegatee => 1,
    },
    manager_category_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
    },
    manager_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
    },
    param_preset_id   => {
        pattern      => '^\d*$',
        is_mandatory => 0,
    },
};

sub getAttrDef { return ATTR_DEF; }

sub methods { return {}; }


sub new {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "manager_id", "manager_category_id" ]);

    # Check if one of the given manager (component) categories match
    # the given manager type.
    eval {
        my $filter = 'component_type.component_type_categories.component_category.component_category_id';
        Entity::Component->find(hash => {
            component_id => $args{manager_id},
            $filter      => $args{manager_category_id}
        });
    };
    if ($@) {
        throw Kanopya::Exception::Internal(
                  error => "Component <" . $args{manager_id} . "> seems not to have the " .
                           "category <" . $args{manager_category_id} . ">, so cannot be used as manager."
              );
    }
    return $class->SUPER::new(%args);
}

sub search {
    my $class = shift;
    my %args = @_;

    General::checkParams(args => \%args, optional => { 'hash' => {} });

    if (defined $args{custom}) {
        if (defined $args{custom}->{category}) {
            # TODO: Support this request in the api
            # $args{hash}->{'manager_category.category_name'} = delete $args{custom}->{category};

            $args{hash}->{'manager_category_id'}
                = ComponentCategory::ManagerCategory->find(
                      hash => { category_name => delete $args{custom}->{category} }
               )->id;
        }
        delete $args{custom};
    }

    return $class->SUPER::search(%args);
}

sub addParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "params" ], optional => { "override" => 0 });

    my $preset;
    eval {
        $self->param_preset->update(params => $args{params}, override => $args{override});
    };
    if ($@) {
        $preset = ParamPreset->new(params => $args{params});
        $self->setAttr(name => 'param_preset_id', value => $preset->id);
        $self->save();
    }
}

sub getParams {
    my $self = shift;
    my %args = @_;

    my $id = $self->param_preset_id;
    if(not defined $id) {
        return {};
    }

    my $param_presets = ParamPreset->get(id => $id);
    return $param_presets->load();
}

1;
