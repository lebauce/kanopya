require('common/service_monitoring.js');
require('common/service_rules.js');
require('common/service_common.js');

function orchestrationPolicyForm(sp_id, policy, grid) {
    var form = new KanopyaFormWizard({
        title      : policy != undefined ? 'Edit the orchestration policy: ' + policy.policy_name :
                                           'Add an orchestration policy',
        type       : 'orchestrationpolicy',
        id         : policy != undefined ? policy.pk : undefined,
        rawattrdef : {
            policy_type : {
                value       : 'orchestration',
                is_editable : 1
            }
        },
        rawsteps : {
            Monitoring : $('<div>'),
            Rules      : $('<div>')
        },
        attrsCallback : function (resource, data) {
            return ajax('POST', '/api/orchestrationpolicy/getPolicyDef', data);
        },
        submitCallback : function(data, $form, opts, onsuccess, onerror) {
            data['orchestration_service_provider_id'] = sp_id;

            // Post the policy
            ajax($(this.form).attr('method').toUpperCase(),
                 $(this.form).attr('action'), data, onsuccess, onerror);
        },
        cancelCallback : function () {
            if (policy == undefined) {
                // Remove policy service provider
                ajax('DELETE', '/api/serviceprovider/' + sp_id);
            }
        },
        callback : function () {
            grid.trigger("reloadGrid");
        }
    });
    form.start();

    // Fill the empty divs given as raw steps
    loadServicesMonitoring('form_orchestrationpolicy_step_Monitoring', sp_id, '', true);
    loadServicesRules('form_orchestrationpolicy_step_Rules', sp_id, '', true);

    // Then manually add the class wizard-ignore to all steps inputs, as the
    // kanopyaformwizard did not it himself because the div was empty as load time.
    $("#form_orchestrationpolicy_step_Monitoring").find(":input").addClass("wizard-ignore");
    $("#form_orchestrationpolicy_step_Rules").find(":input").addClass("wizard-ignore");
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
function load_orchestration_policy_details(policy, grid_id) {
    var sp_id;

    if (policy.orchestration && policy.orchestration.service_provider_id) {
        sp_id = policy.orchestration.service_provider_id;

    } else {
        // default orchestration policy is not linked to a sp, so we create it
        sp_id = createPolicyServiceProvider();
    }

    orchestrationPolicyForm(sp_id, policy, $('#' + grid_id));
}

function addOrchestrationPolicy(grid) {
    var sp_id = createPolicyServiceProvider();
    orchestrationPolicyForm(sp_id, undefined, grid);
}
