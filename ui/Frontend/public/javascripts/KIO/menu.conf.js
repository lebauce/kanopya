// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"
require('common/workflows.js');

var mainmenu_def = {
    'Services' : {
        masterView : [ {
            label : 'Overview',
            id : 'services_overview',
            onLoad : function(cid) { require('KIO/services.js'); servicesList(cid); }
        } ],
        json : {
            url       : '/api/externalcluster?components.component_id=',
            label_key : 'externalcluster_name',
            id_key    : 'pk',
            submenu   : [ {
                label : 'Overview',
                id : 'service_overview',
                onLoad : function(cid, eid) { require('common/service_dashboard.js'); loadServicesOverview(cid, eid); },
                icon : 'dashboard',
            }, {
                label : 'Configuration',
                id : 'service_configuration',
                onLoad : function(cid, eid) { require('KIO/services_config.js'); loadServicesConfig(cid, eid); },
                icon : 'configuration'
            }, {
                label : 'Resources',
                id : 'service_resources',
                onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesResources(cid, eid); },
                icon : 'resources'
            }, {
                label : 'Monitoring',
                id : 'service_monitoring',
                onLoad : function(cid, eid) { require('common/service_monitoring.js'); loadServicesMonitoring(cid, eid, 'external'); },
                icon : 'monitoring'
            }, { label : 'Rules',
                 id : 'service_rules',
                 onLoad : function(cid, eid) { /* require('common/service_rules.js'); */ loadServicesRules(cid, eid, 'external'); },
                 icon : 'rules'
            }, { label : 'Events & Alerts',
                 id : 'events_alerts',
                 onLoad : function(cid, eid) { require('common/service_eventsalerts.js'); loadServiceEventsAlerts(cid, eid); },
                 icon : 'alert'
            }, { label : 'Analysis',
                 id : 'service_analysis',
                 onLoad : function(cid, eid) { require('common/service_analysis.js'); loadServiceAnalysis(cid, eid); },
                 icon : 'analysis',
                 info : {img:'images/info/scatter-plots-shape.png'}
            } ]
        }
    },
    'Administration' : {
        'Technical Services' : [ {
            label : 'Technical Services',
            id : 'technicalservices',
            onLoad : function(cid) { require('KIO/technicalservices.js'); technicalserviceslist(cid); }
         } ],
        'Monitoring' :  [ {
            label : 'Scom',
            id : 'scommanagement',
            onLoad : function(cid, eid) { require('KIO/scommanagement.js'); scomManagement(cid, eid); }
        } ],
        'Workflows' : [ {
            label : 'Workflow Management',
            id : 'workflowmanagement',
            onLoad : sco_workflow
        } ],
        'General' : [ {
            label : 'Settings',
            id : 'monitorsettings',
            onLoad : function(cid, eid) { require('KIO/monitorsettings.js'); loadMonitorSettings(cid, eid); }
        } ],
        'Time periods' : [ {
            label : 'Time periods',
            id : 'timeperiods',
            onLoad : function(cid, eid) { timePeriods.load(cid, eid); }
        } ],
        'Right Management' : [ {
            label : 'Users',
            id : 'users',
            onLoad : function(cid, eid) { require('common/users.js'); users.load_content(cid, eid); }
        }, {
            label : 'Groups',
            id : 'groups',
            onLoad : function(cid, eid) { require('common/users.js'); groupsList(cid, eid); }
        }, {
            label : 'Permissions',
            id : 'permissions',
            onLoad : function(cid, eid) { require('common/users.js'); permissions(cid, eid); }
        } ]
    }
};

var details_def = {
    'workflowmanagement' : { onSelectRow : workflowdetails }
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
