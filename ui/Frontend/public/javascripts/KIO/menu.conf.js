// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"

require('KIO/workflows.js');
require('servicemenudefinition.js');

var mainmenu_def = {
    'Services'          : getServiceMenuDefinition('externalcluster'),
    'Administration'    : {
        //'Kanopya'          : [],
        'Monitoring'       : [{label : 'Scom', id : 'scommanagement',onLoad : function(cid, eid) { require('KIO/scommanagement.js'); scomManagement(cid, eid); }}],
        'Right Management' :  [
                               {label : 'Users', id : 'users', onLoad : function(cid, eid) { require('KIO/users.js'); usersList(cid, eid); }},
                               {label : 'Groups', id : 'groups',onLoad : function(cid, eid) { require('KIO/users.js'); groupsList(cid, eid); }},
                               {label : 'Permissions', id : 'permissions', onLoad : function(cid, eid) { require('KIO/users.js'); permissions(cid, eid); }}
                               ],
        'Workflows'        : [
            { label : 'Overview', id : 'workflows_overview', onLoad : workflowsoverview },
            { label : 'Workflow Management' , id : 'workflowmanagement', onLoad : sco_workflow },
        ],
    },
};

var details_def = {
        'services_list' : { link_to_menu : 'yes', label_key : 'externalcluster_name'},
        /*'service_ressources_list' : {
            tabs : [
                        { label : 'Node', id : 'node', onLoad : function(cid, eid) {  } },
                        { label : 'Rules', id : 'rules', onLoad : node_rules_tab },
                    ],
            title : { from_column : 'externalnode_hostname' }
        },*/
        'workflowmanagement' : { onSelectRow : workflowdetails },
};

function node_detail_tab(cid, eid) {

}

function rule_detail_tab(cid, eid) {

}



// This function load a grid with the list of current service's nodes for state corelation with rules
function rule_nodes_tab(cid, eid) {
    
    function verifiedRuleNodesStateFormatter(cell, options, row) {
        var VerifiedRuleFormat;
            // Where rowid = rule_id
            
            console.log(row.pk);
            console.log(eid);
            
            $.ajax({
                 url: '/api/externalnode/' + row.pk + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + eid,
                 async: false,
                 success: function(answer) {
                    if (answer.length == 0) {
                        VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                    } else if (answer[0].verified_noderule_state == undefined) {
                        VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                    } else if (answer[0].verified_noderule_state == 'verified') {
                        VerifiedRuleFormat = "<img src='/images/icons/broken.png' title='broken' />";
                    } else if (answer[0].verified_noderule_state == 'undef') {
                        VerifiedRuleFormat = "<img src='/images/icons/down.png' title='down' />";
                    }
                  }
            });
        return VerifiedRuleFormat;
    }
    
    var oid;
    $.ajax({
         url: '/api/externalnode/' + eid,
                 async: false,
                 success: function(answer) {
                    oid = answer.outside_id;
                  }
            });
    
    var loadNodeRulesTabGridId = 'rule_nodes_tabs';
    console.log(oid);
    create_grid( {
        url: '/api/externalnode?outside_id=' + oid,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'rule_nodes_grid',
        colNames: [ 'id', 'hostname', 'state' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'externalnode_hostname', index: 'externalnode_hostname', width: 110,},
            { name: 'verified_noderule_state', index: 'verified_noderule_state', width: 60, formatter: verifiedRuleNodesStateFormatter,}, 
        ],
        action_delete : 'no',
    } );
}

// Placeholder handler wich display elem json from rest api
function displayJSON (container_id, elem_id) {
    $.getJSON('api/entity/'+elem_id, function (data) {
        $('#'+container_id).append('<div>' + JSON.stringify(data) + '</div>');
    });
}

function reloadServices () {
    // Trigger click callback wich relaod grid content and dynamic menu
    $('#menuhead_Services').click();
}
