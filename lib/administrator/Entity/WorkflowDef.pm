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

use Log::Log4perl 'get_logger';

my $log = get_logger("");
my $errmsg;

use constant ATTR_DEF => {
    workflow_def_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
    workflow_def_origin => {
        pattern      => '^\d+$',
        is_mandatory => 0,
        is_extended  => 0
    },
    param_presets => {
        is_virtual   => 1,
    },
};

sub methods {
  return {
    updateParamPreset => {
        description => 'updateParamPreset',
        perm_holder => 'entity',
    },
  }
}

sub getAttrDef { return ATTR_DEF; }


=pod
=begin classdoc

@constructor

Create a new WorkflowDef

@optional params
@return new WorkflowStep instance

=end classdoc
=cut

sub new {
    my ($class, %args) = @_;

    General::checkParams(args => \%args, required => [ "workflow_def_name" ],
                                         optional => {params => undef});

    my $params = delete $args{params};

    my $self = $class->SUPER::new(%args);

    if (defined $params) {
        $self->setParamPreset(params => $params);
    }

    return $self;
}


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

Set parameters to WorkflowDef

@param params hash ref of parameters

=end classdoc
=cut

sub setParamPreset {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "params" ]);

    # TODO remove current paramPreset if exists (or use updateParamPreset)

    my $preset = ParamPreset->new(params => $args{params});
    $self->param_preset_id($preset->param_preset_id);
}


=pod
=begin classdoc

Update parameters if a WorkflowDef instance.

@param params hash ref of parameters

=end classdoc
=cut

sub updateParamPreset{
    my ($self,%args) = @_;

    General::checkParams(args => \%args, required => [ "params" ]);

    my $preset;
    eval {
        $preset = $self->param_preset;
    };
    if ($@) {
        $errmsg = 'could not retrieve any param preset for workflow: '.$@;
        $log->error($errmsg);
    } else {
        $preset->update( params => $args{params} );
    }
}


=pod
=begin classdoc

Retrieve parameters to WorkflowDef

=end classdoc
=cut

sub paramPresets {
    my $self = shift;

    my $param_preset_id = $self->param_preset_id;
    return {} if ! $param_preset_id;

    my $preset;
    eval {
        $preset = $self->param_preset;
    };
    if ($@) {
        $errmsg = 'could not retrieve any param preset for workflow: '.$@;
        $log->error($errmsg);
    } else {
        return $preset->load();
    }
}


=pod
=begin classdoc

This method delete WorkflowDef and its associated params preset

=end classdoc
=cut

sub delete {
    my $self = shift;

    my $preset;
    eval {
        $preset = $self->param_preset;
    };
    if (not $@) {
        $preset->delete();
    }

    $self->SUPER::delete();
}

1;
