// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"

require('KIO/workflows.js');

var mainmenu_def = {
    'Services'   : {
        //onLoad : load_services,
        masterView : [
                      {label : 'Overview', id : 'services_overview', onLoad : function(cid) { require('KIO/services.js'); servicesList(cid); }, info : { url : 'doc/services.html'}}
                      ],
        json : {url         : '/api/externalcluster',
                label_key   : 'externalcluster_name',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesOverview(cid, eid);}, info : { url : 'doc/widget_dash_info.html'}},
                               {label : 'Configuration', id : 'service_configuration', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesConfig(cid, eid);}},
                               {label : 'Ressources', id : 'service_ressources', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesRessources(cid, eid);}},
                               {label : 'Monitoring', id : 'service_monitoring', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesMonitoring(cid, eid);}},
                               {label : 'Rules', id : 'service_rules', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesRules(cid, eid);}},
                               {label : 'Workflows', id : 'workflows', onLoad : workflowslist}
                               ]
                }
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' :  [
                               {label : 'Users', id : 'users', onLoad : function(cid, eid) { require('KIO/users.js'); usersList(cid, eid); }},
                               {label : 'Groups', id : 'groups',onLoad : function(cid, eid) { require('KIO/users.js'); groupsList(cid, eid); }},
                               {label : 'Permissions', id : 'permissions', onLoad : function(cid, eid) { require('KIO/users.js'); permissions(cid, eid); }}
                               ],
        'Monitoring'       : [],
        'Workflows'        : [{ label : 'Workflow Management' , id : 'workflowmanagement', onLoad : sco_workflow }]
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
