require('common/service_monitoring.js');
require('common/service_rules.js');
require('common/service_common.js');

// Return a hash with data of all grids in container cont_id
// keys are grid url
function exportGrids(cont_id) {
    var res = {};
    $('#' + cont_id + ' .ui-jqgrid-btable').each(function() {
        var data = $(this).jqGrid('getRowData');
        var grid_url = $(this).jqGrid('getGridParam', 'url');
        res[grid_url] = data;
    });
    return res;
}

//Generic callback to add row in grid from modalForm data
function beforeDataSubmit(data, object, options, form, grid) {
    var format_data = {};
    $(data).each(function(entry) {format_data[this.name]=this.value});
    form.closeDialog();
    grid.jqGrid('addRowData',1,format_data);
}

function saveOrchestrationPolicy(sp_id, data) {
    var policy_params = {};

    $(data).each(function() {
        policy_params[this.name] = this.value;
    })
    delete policy_params.monitoring;
    delete policy_params.rules;

    policy_params['orchestration_service_provider_id'] = sp_id;

    // Post policy
    $.ajax({
        type        : 'POST',
        url         : 'api/policy',
        data        : policy_params,
     });
}

function orchestrationPolicyForm(policy_opts, sp_id, edit_mode, grid) {
    var policy_opts_spec = {
        dialogParams  : {
            //width       : 1000,
        },
        formwizardParams  : {
            inDuration   : 0,
            outDuration  : 0,
            inAnimation  : {},
            outAnimation : {},
        },
        beforeSubmit: function(data, object, options, form) {
            saveOrchestrationPolicy(sp_id, data);
            grid.trigger("reloadGrid");
            form.closeDialog();
            return false;
        },
        cancel      : function () {
            if ( !edit_mode ) {
                // Remove policy service provider
                $.ajax({
                    type     : 'DELETE',
                    url      : 'api/serviceprovider/' + sp_id,
                 });
              }
        },
    };

    var form = new PolicyForm($.extend({}, policy_opts, policy_opts_spec));
    form.start();

    $('#form_policy').append($('<div>', { id:"policy_monitoring", 'class':'custom_policy_step hidden' }));
    loadServicesMonitoring('policy_monitoring', sp_id, '', true);

    $('#form_policy').append($('<div>', { id:"policy_rules", 'class':'custom_policy_step hidden' }));
    loadServicesRules('policy_rules', sp_id, '', true);

    $(form.form).on('step_shown', function(event, step_info) {
        $('#form_policy .custom_policy_step').hide();
        var step = step_info.currentStep;
        if (step === 'form_policy_stepMonitoring') {
            $("#policy_monitoring").show();
        } else if (step === 'form_policy_stepRules') {
            $("#policy_rules").show();
        }
    });
}

// Associate to service provider <sp_id> the manager <type> corresponding to component installed on kanopya cluster
function associateAdminManager(sp_id, component_category, manager_type) {
    var manager_id = findManager(component_category)[0].pk;

    // Associate sp to manager
    $.ajax({
        type    : 'POST',
        url     : 'api/serviceprovider/' + sp_id + '/addManager',
        async   : false,
        data    : {
            manager_id   : manager_id,
            manager_type : manager_type
        }
     });
}

function createPolicyServiceProvider() {
    // Create policy service provider
    var sp_id;
    $.ajax({
       type     : 'POST',
       url      : 'api/serviceprovider',
       async    : false,
       success  : function(data) {
           sp_id = data.service_provider_id;
       }
    });

    associateAdminManager(sp_id, 'Collectormanager', 'collector_manager');
    associateAdminManager(sp_id, 'Workflowmanager', 'workflow_manager');

    return sp_id;
}

// Edit existing policy
function load_orchestration_policy_details(policy_opts, policy, grid_id) {
    var sp_id;
    var edit_mode = 1;

    if (policy.orchestration && policy.orchestration.service_provider_id) {
        sp_id = policy.orchestration.service_provider_id;
    } else {
        // default orchestration policy is not linked to a sp, so we create it
        sp_id = createPolicyServiceProvider();
        edit_mode = 0;
    }

    orchestrationPolicyForm(
            policy_opts,
            sp_id,
            edit_mode,
            $('#' + grid_id)
    );
}

function addOrchestrationPolicy(policy_opts, grid) {

    var sp_id = createPolicyServiceProvider();

    orchestrationPolicyForm(policy_opts, sp_id, 0, grid);
}
