# Copyright © 2013 Hedera Technology SAS
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

=pod
=begin classdoc

Link between a rule and a workflow def
Hold the workflow def params for the associated rule

=end classdoc
=cut

package WorkflowDefRule;
use base BaseDB;

use strict;
use warnings;

use Data::Dumper;
use Log::Log4perl 'get_logger';

use TryCatch;
my $err;

my $log = get_logger("");

use constant ATTR_DEF => {
    workflow_def_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
    },
    rule_id => {
        pattern      => '^\d*$',
        is_mandatory => 1,
        is_delegatee => 1,
    },
    param_presets => {
        is_virtual   => 1,
        is_editable  => 1
    },
};

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Set/get the virtual attribute param_preset.

=end classdoc
=cut

sub paramPresets {
    my ($self, @args) = @_;

    if (scalar(@args)) {
        if (defined $self->param_preset) {
            $self->param_preset->remove();
        }
        $self->param_preset_id(ParamPreset->new(params => pop @args)->id);
    }
    else {
        try {
            return $self->param_preset->load();
        }
        catch ($err) {
            return {};
        }
    }
}

1;
