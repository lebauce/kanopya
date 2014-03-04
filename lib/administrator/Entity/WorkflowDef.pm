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


=pod
=begin classdoc

WorkflowDef class supplies a workflow definition used as a patter to instanciate new workflows.

To a WorkflowDef instance are associated a sequence of operations (through the WorkflowStep class)
and some Parameters.

=end classdoc
=cut

package Entity::WorkflowDef;
use base 'Entity';

use strict;
use warnings;
use WorkflowStep;
use TryCatch;

use Log::Log4perl 'get_logger';

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    workflow_def_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
    },
    param_presets => {
        is_virtual   => 1,
        is_editable  => 1,
    },
};

sub methods {
    return {};
}

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

Add a new Operation to the WorkflowDef sequence of operations.

@param operationtype_id the operation type id

@return Corresponding WorkflowStep instance

Create a new WorkflowDef

=end classdoc
=cut

sub addStep {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "operationtype_id" ]);

    return  WorkflowStep->new(workflow_def_id  => $self->workflow_def_id,
                              operationtype_id => $args{operationtype_id});
}


=pod
=begin classdoc

This method delete WorkflowDef and its associated params preset

=end classdoc
=cut

sub delete {
    my $self = shift;

    if (defined $self->param_preset) {
        $self->param_preset->remove();
    }

    $self->SUPER::delete();
}


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
