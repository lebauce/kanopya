// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"

var mainmenu_def = {
    'Services'   : {
        //onLoad : load_services,
        masterView : [
                      {label : 'Overview', id : 'services_overview', onLoad : function(cid) { require('KIO/services.js'); servicesList(cid); }}
                      ],
        json : {url         : '/api/externalcluster',
                label_key   : 'externalcluster_name',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesOverview(cid, eid);}},
                               {label : 'Configuration', id : 'service_configuration', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesConfig(cid, eid);}},
                               {label : 'Ressources', id : 'service_ressources', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesRessources(cid, eid);}},
                               {label : 'Monitoring', id : 'service_monitoring', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesMonitoring(cid, eid);}},
                               {label : 'Rules', id : 'service_rules', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesRules(cid, eid);}},
                               ]
                }
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' :  [
                               {label : 'Users', id : 'users', onLoad : function(cid, eid) { require('KIO/users.js'); usersList(cid, eid); }},
                               {label : 'Groups', id : 'groups',onLoad : function(cid, eid) { require('KIO/users.js'); groupsList(cid, eid); }},
                               {label : 'Permissions', id : 'permissions'}
                               ],
        'Monitoring'       : [],
        'Workflows'        : [{ label : 'SCO' , id : 'workflow_sco', onLoad : _sco_workflow }]
    },
};

function _sco_workflow(cid, eid) {
    require('KIO/workflows.js');
    sco_workflow(cid, eid);
}

var details_def = {
        'services_list' : { link_to_menu : 'yes', label_key : 'externalcluster_name'},
        'service_ressources_list' : [{ label : 'Server details' , id : 'service_ressource' }]
};

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
