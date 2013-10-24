#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Pod;
use Data::Dumper;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
    level  => 'DEBUG',
    file   => 'workflowDef.log',
    layout => '%F %L %p %m%n'
});
my $log = get_logger("");

use Kanopya::Database;
use BaseDB;
use General;
use Entity;
use Entity::WorkflowDef;
use ParamPreset;
use Kanopya::Tools::TestUtils 'expectedException';
use Operationtype;

Kanopya::Database::authenticate(login => 'admin', password => 'K4n0pY4');

main();

sub main {
    Kanopya::Database::beginTransaction;

    my $params = { param_1 => 'value_1',
                   param_2 => 'value_2'};

    my $wf;
    my $wf2;

    lives_ok {
        $wf  = Entity::WorkflowDef->new(workflow_def_name => 'workflowdef_test');
        $wf2 = Entity::WorkflowDef->new(workflow_def_name => 'workflowdef_test_2', params => $params);

        my $get_params_empty = $wf->paramPresets;
        while (my ($k,$v) = each(%$get_params_empty)) {
                die 'Error WorkflowDef should not have';
        }
        my $get_params_2 = $wf2->paramPresets;
        while (my ($k,$v) = each(%$get_params_2)) {
            if ($v != $params->{$k}) {
                die 'Error WorkflowDef should have defined params';
            }
        }

    } 'WorkflowDef creation with and without params';


    $wf->setParamPreset(params => $params);

    my $get_params = $wf->paramPresets;

    lives_ok {
        while (my ($k,$v) = each(%$params)) {
            if ($v != $get_params->{$k}) {
                die 'Error during setParamPreset';
            }
        }
    } 'Set params';

    my $params_update = { param_1 => 'value_1_bis',
                          param_3 => 'value_3'};

    $wf->updateParamPreset(params => $params);

    $get_params = $wf->paramPresets;

    lives_ok {
        if ($get_params->{param1} != 'value_1_bis' ||
            $get_params->{param2} != 'value_2' ||
            (defined $get_params-> {param3})) {
                die 'Error during updateParamPreset';
            }
    } 'Get params';


    lives_ok {
        my @ops = Operationtype->search();
        my $op1 = pop @ops;
        my $op2 = pop @ops;

        $wf->addStep(operationtype_id => $op1->id);
        $wf->addStep(operationtype_id => $op2->id);

        my @steps = WorkflowStep->search(hash     => { workflow_def_id => $wf->id },
                                                       order_by        => 'workflow_step_id asc');

        if ($steps[0]->operationtype_id != $op1->id || $steps[1]->operationtype_id != $op2->id) {
            die 'Error in addStep'
        }
    } 'AddStep';

    lives_ok {
        my $id1 = $wf->id;
        my $pp_id1 = $wf->param_preset_id;

        Entity->get(id => $id1);
        ParamPreset->get(id => $pp_id1);

        $wf->delete();

        expectedException {
            ParamPreset->get(id => $pp_id1);
        } 'Kanopya::Exception::Internal::NotFound', 'ParamPreset should be deleted';

        expectedException {
            Entity->get(id => $id1);
        } 'Kanopya::Exception::Internal::NotFound', 'Workflow should be deleted';

        $wf2->delete();

    } 'Deletion';

    Kanopya::Database::rollbackTransaction;
}
1;