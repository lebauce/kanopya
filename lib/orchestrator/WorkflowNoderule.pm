#    Copyright © 2012 Hedera Technology SAS
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
# Created 3 juillet 2012

package WorkflowNoderule;

use strict;
use warnings;
use base 'BaseDB';
use NodemetricRule;
use Log::Log4perl "get_logger";
my $log = get_logger("orchestrator");

use constant ATTR_DEF => {
    externalnode_id         =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    nodemetric_rule_id      =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    workflow_id             =>  {pattern       => '^.*$',
                                 is_mandatory   => 1,
                                 is_extended    => 0,
                                 is_editable    => 1},
    workflow_untriggerable_timestamp =>  {pattern       => '^.*$',
                                 is_mandatory   => 0,
                                 is_extended    => 0,
                                 is_editable    => 1},
};

sub getAttrDef { return ATTR_DEF; }

sub workflowState{
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'externalnode_id',
                                                       'nodemetric_rule_id',
                                                     ]);

    my $workflow_noderule;
    eval{
        $workflow_noderule = $class->find(hash => {
            externalnode_id    => $args{externalnode_id},
            nodemetric_rule_id => $args{nodemetric_rule_id},
        });
    };

    if(defined $workflow_noderule){
        my $workflow_id = $workflow_noderule->getAttr(name => 'workflow_id');
        my $workflow    = Workflow->get(id => $workflow_id);

        if ($workflow->state eq 'running'){
            $log->info('A workflow is already running');
            return {state => 'running'};
        }
        elsif ($workflow->state eq 'cancelled') {
            $log->info('Workflow done or cancelled, delete workflow noderule');
            $workflow_noderule->delete();
            return {state => 'ready_to_launch'};
        }
        elsif ($workflow->state eq 'done') {
            my $rule = NodemetricRule->get(id => $workflow_noderule->nodemetric_rule_id);
            my $delay = $rule->workflow_def->getParamPreset()->{specific}->{delay};
            if (defined $delay && $delay > 0) {

                if (not defined $workflow_noderule->workflow_untriggerable_timestamp) {
                    $workflow_noderule->setAttr(name => 'workflow_untriggerable_timestamp', value => time() + $delay);
                    $workflow_noderule->save();
                    $log->info('Workflow <'.$workflow_id.'> done, delaying time for <'.($delay).'> sec');
                    return {state => 'delayed'};
                }
                else {
                    my $delta = $workflow_noderule->workflow_untriggerable_timestamp - time();
                    if ($delta <= 0) {
                        $log->info('Workflow <'.$workflow_id.'> done, end of delay time, delete workflow noderule');
                        $workflow_noderule->delete();
                        return {state => 'ready_to_launch'};
                    }
                    else {
                        $log->info('Workflow <'.$workflow_id.'> done, still delaying time for <'.($delta).'> sec');
                        return {state => 'delayed'};
                    }
                }
            }
            else {
                $log->info('Workflow <'.$workflow_id.'> done, <0 or undefined delay time, delete workflow noderule');
                $workflow_noderule->delete();
                return {state => 'ready_to_launch'};
            }
        }
        else {
            throw Kanopya::Exception(error => 'unknown workflow state <'.($workflow->state).'>');
        }
    }

    $log->info('workflow_noderule extnode_id <'.$args{externalnode_id}.'> nodemetric_rule_id <'.$args{nodemetric_rule_id}.'> not defined');

    return {state => 'ready_to_launch'};
}

sub isWorkflowRunning{
    my ($class, %args) = @_;
    General::checkParams(args => \%args, required => [ 'externalnode_id',
                                                       'nodemetric_rule_id',
                                                     ]);

    my $workflow_noderule;
    eval{
        $workflow_noderule = $class->find(hash => {
            externalnode_id    => $args{externalnode_id},
            nodemetric_rule_id => $args{nodemetric_rule_id},
        });
    };

    if(defined $workflow_noderule){
        my $workflow_id = $workflow_noderule->getAttr(name => 'workflow_id');
        my $workflow    = Workflow->get(id => $workflow_id);

        if ($workflow->state eq 'running'){
            $log->info('A workflow is already running');
            return 1;
        }
        else {
            $log->info('Workflow done or cancelled, delete workflow noderule');
            $workflow_noderule->delete();
            return 0;
        }
    }

    $log->info('workflow_noderule extnode_id <'.$args{externalnode_id}.'> nodemetric_rule_id <'.$args{nodemetric_rule_id}.'> not defined');
    return 0;
}
1;
