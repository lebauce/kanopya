
function getServiceMenuDefinition(type) {
    var     ext = undefined;
    if (type === 'externalcluster') ext = 'external';
    return {
        masterView : [
                      {label : 'Overview', id : 'services_overview', onLoad : function(cid) { require('KIO/services.js'); servicesList(cid); }}
                      ],
        json : {url         : '/api/serviceprovider',
                label_key   : type + '_name',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesOverview(cid, eid);}},
                               {label : 'Configuration', id : 'service_configuration', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesConfig(cid, eid);}},
                               {label : 'Ressources', id : 'service_ressources', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesRessources(cid, eid, ext);}},
                               {label : 'Monitoring', id : 'service_monitoring', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesMonitoring(cid, eid, ext);}},
                               {label : 'Rules', id : 'service_rules', onLoad : function(cid, eid) { require('KIO/services.js'); loadServicesRules(cid, eid, ext);}},
                               {label : 'Workflows', id : 'workflows', onLoad : function(cid, eid) { require('KIO/workflows.js'); workflowslist(cid, eid); } }
                               ]
                }
    };
}
