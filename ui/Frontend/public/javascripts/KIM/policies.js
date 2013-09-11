require('jquery/jquery.form.js');
require('jquery/jquery.validate.js');
require('jquery/jquery.form.wizard.js');
require('KIM/orchestration_policy.js');

function load_policy_content (container_id) {
    var policy_type = container_id.split('_')[1];

    function createAddPolicyButton(cid, grid) {
        var button = $("<button>", {html : 'Add a ' + policy_type + ' policy'}).button({
            icons   : { primary : 'ui-icon-plusthick' }
        });

        button.bind('click', function() {
            if (policy_type != 'orchestration') {
                // Use the kanopyaformwizard for policies
                (new KanopyaFormWizard({
                    title      : 'Add a ' + policy_type + ' policy',
                    type       : policy_type + 'policy',
                    reloadable : true,
                    rawattrdef : {
                        policy_type : {
                            value : policy_type
                        }
                    },
                    attrsCallback : function (resource, data, trigger) {
                        var args = { params : data, trigger : trigger };

                        // Make the call to attributes our  self to force using POST, as
                        // we need to give JSON formated params
                        return ajax('POST', '/api/attributes/' + policy_type + 'policy', args);
                    },
                    callback : function () { grid.trigger("reloadGrid"); }
                })).start();
            } else {
                addOrchestrationPolicy(grid);
            }
        });
        var action_div=$('#' + cid).prevAll('.action_buttons');
        $(action_div).append(button);
    };

    var container = $('#' + container_id);
    var grid = create_grid({
        url: '/api/policy?policy_type=' + policy_type,
        content_container_id: container_id,
        grid_id: policy_type + '_policy_list',
        colNames: [ 'ID', 'Name', 'Description' ],
        colModel: [ { name:'policy_id',   index:'policy_id',   width:60, sorttype:"int", hidden:true, key:true},
                    { name:'policy_name', index:'policy_name', width:300 },
                    { name:'policy_desc', index:'policy_desc', width:500 } ],
        details: { onSelectRow : load_policy_details }
    });

    createAddPolicyButton(container_id, grid);
}

function load_policy_details (elem_id, row_data, grid_id) {
    var policy;
    $.ajax({
        type     : 'GET',
        async    : false,
        url      : '/api/policy/' + elem_id,
        dataTYpe : 'json',
        success  : $.proxy(function(d) {
            policy = d;
        }, this)
    });

    // Special management for Orchestration policy
    if (policy.policy_type == 'orchestration') {
        load_orchestration_policy_details(policy, grid_id);

    } else {
        var currentdata = policy;
        // Use the kanopyaformwizard for policies
        (new KanopyaFormWizard({
            title      : 'Edit the ' + policy.policy_type + ' policy: ' + policy.policy_name,
            type       : policy.policy_type + 'policy',
            id         : policy.pk,
            reloadable : true,
            attrsCallback : function (resource, data, trigger) {
                // If it is the first call to get attributes, use the original policy as params
                // to get the proper dynamic attr defintion.
                if (! $.isEmptyObject(data)) {
                    currentdata = data;
                }

                var args = { params : currentdata, trigger : trigger };
                var attrsdef = ajax('POST', '/api/attributes/' + policy.policy_type + 'policy', args);
                for (var attr in attrsdef.attributes) {
                    if (attrsdef.attributes[attr].value == undefined) {
                        delete currentdata[attr];
                    }
                }
                return attrsdef;
            },
            valuesCallback : function (type, id, attributes) {
                return currentdata;
            },
            callback : function () { $('#' + grid_id).trigger("reloadGrid"); }
        })).start();
    }
}
