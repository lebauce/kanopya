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

package ServiceProviderManager;
use base 'BaseDB';

use strict;
use warnings;

use ParamPreset;

use Hash::Merge;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger("");

use constant ATTR_DEF => {
    service_provider_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    manager_type => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    manager_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
   param_preset_id   => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub getDelegatee {
    my $self = shift;
    my $class = ref $self;

    if (!$class) {
        return "Entity::ServiceProvider";
    } else {
        return $self->service_provider;
    }
}

sub addParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "params" ], optional => { "override" => 0 });

    my $preset;
    eval {
        $preset = $self->param_preset;

        if ($args{override}) {
            $preset->update(params => $args{params});
        }
        else {
            $preset->store(params => $args{params});
        }
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
