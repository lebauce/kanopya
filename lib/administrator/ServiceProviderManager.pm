# Copyright fazf© 2011-2012 Hedera Technology SAS
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

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    service_provider_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    service_provider_manager_type => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    service_provider_manager_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    service_provider_manager_params => {
        pattern      => '^.*$',
        is_mandatory => 0,
        is_extended  => 0
    },
};

sub getAttrDef { return ATTR_DEF; }

sub addParams {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "params" ]);

    my $preset;
    eval {
        $preset = ParamPreset->get(id => $self->getAttr(name => 'manager_params'));

        if ($args{override}) {
            $preset->update(params => $args{params});
        }
        else {
            $preset->store(params => $args{params});
        }
    };
    if ($@) {
        $preset = ParamPreset->new(name => 'manager_params', params => $args{params});
        $self->setAttr(name  => 'manager_params',
                       value => $preset->getAttr(name => 'param_preset_id'));
        $self->save();
    }
}

sub getParams {
    my $self = shift;
    my %args = @_;

    my $param_presets = ParamPreset->get(id => $self->getAttr(name => 'manager_params'));

    return $param_presets->load();
}

1;
