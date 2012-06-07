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

package WorkflowDef;
use base 'BaseDB';

use strict;
use warnings;

use WorkflowStep;

use Data::Dumper;
use Log::Log4perl 'get_logger';

my $log = get_logger('administrator');

use constant ATTR_DEF => {
    workflow_def_name => {
        pattern      => '^.*$',
        is_mandatory => 1,
        is_extended  => 0
    },
};

sub methods {
  return {
    'setParamPreset'    => {
      'description' => 'setParamPreset',
      'perm_holder' => 'entity'
    },
    'addStep'           => {
      'description' => 'addStep',
      'perm_holder' => 'entity'
    }
  }
}

sub getAttrDef { return ATTR_DEF; }

sub new {
    my $class = shift;
    my %args = @_;

    my $params;
    if (defined $args{params}) {
        $params = delete $args{params};
    }

    my $self = $class->SUPER::new(%args);

    if (defined $params) {
        $self->setParamPreset(params => $params);
    }

    return $self;
}

sub addStep {
    my ($self, %args) = @_;

    General::checkParams(args => \%args, required => [ "operationtype_id" ]);
    
    my $workflow_def_id = $self->getAttr(name => 'workflow_def_id');
    my $operationtype_id = $args{operationtype_id};
    
    my $workflow_step = WorkflowStep->new(workflow_def_id => $workflow_def_id, operationtype_id => $operationtype_id); 
}

sub setParamPreset {
    my $self = shift;
    my %args = @_;

    General::checkParams(args => \%args, required => [ "params" ]);

    my $preset = ParamPreset->new(name => 'workflow_def_params', params => $args{params});
    $self->setAttr(name  => 'param_preset_id',
                   value => $preset->getAttr(name => 'param_preset_id'));
    $self->save();
}


sub getParamPreset{
    my ($self,%args) = @_;
    my $preset = ParamPreset->get(id => $self->getAttr(name => 'param_preset_id'));
    return $preset->load();
}

1;
