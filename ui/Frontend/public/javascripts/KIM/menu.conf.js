require('KIM/iaas.js');
require('KIM/customers.js');
require('KIM/servicetemplates.js');
require('KIM/policies.js');

// each link will show the div with id "view_<id>" and hide all div in "#view-container"
// onLoad handlers are called with params (content_container_id)
var mainmenu_def = {
    'Infrastructure' : {
        'Compute' : [ { label : 'Overview', id : 'compute_overview'},
                      { label : 'Hosts', id : 'hosts'} ],
        'Storage' : [ { label : 'Overview', id : 'storage_overview'} ],
        'IaaS'    : [ { label : 'IaaS', id : 'iaas', onLoad : load_iaas_content},
                      { label : 'Log & Event', id : 'logs'} ],
        'Network' : [],
        'System'  : [],
    },
    'Business' : {
        'Policies'          : [ { label : 'Hosting',     id : 'hosting_policy',     onLoad : load_policy_content },
                                { label : 'Storage',     id : 'storage_policy',     onLoad : load_policy_content },
                                { label : 'Network',     id : 'network_policy',     onLoad : load_policy_content },
                                { label : 'System',      id : 'system_policy',      onLoad : load_policy_content },
                                { label : 'Scalability', id : 'scalability_policy', onLoad : load_policy_content },
                                { label : 'Billing',     id : 'billing_policy',     onLoad : load_policy_content }],
        'Service templates' : [ { label : 'Service templates', id : 'service_template', onLoad : load_service_template_content } ],
        'Customers'         : [ { label : 'Customers', id : 'customers', onLoad: customers.load_content }]
    },
    'Services'          : {
        masterView : [
                      {label : 'Overview', id : 'services_overview', onLoad : function(cid) { require('KIM/services.js'); servicesList(cid); }}
                      ],
        json : {url         : '/api/serviceprovider',
                label_key   : 'cluster_name',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : function(cid, eid) { require('common/service_dashboard.js'); loadServicesOverview(cid, eid);}},
                               {label : 'Configuration', id : 'service_configuration', onLoad : function(cid, eid) { require('common/service_common.js'); loadServicesConfig(cid, eid);}},
                               {label : 'Ressources', id : 'service_ressources', onLoad : function(cid, eid) { require('KIM/services.js'); loadServicesRessources(cid, eid);}},
                               {label : 'Monitoring', id : 'service_monitoring', onLoad : function(cid, eid) { require('common/service_monitoring.js'); loadServicesMonitoring(cid, eid);}},
                               {label : 'Rules', id : 'service_rules', onLoad : function(cid, eid) { require('common/service_rules.js'); loadServicesRules(cid, eid);}},
                               {label : 'Workflows', id : 'workflows', onLoad : function(cid, eid) { require('common/workflows.js'); workflowslist(cid, eid); } }
                               ]
                }
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' :  [
                               {label : 'Users', id : 'users', onLoad : function(cid, eid) { require('common/users.js'); usersList(cid, eid); }},
                               {label : 'Groups', id : 'groups',onLoad : function(cid, eid) { require('common/users.js'); groupsList(cid, eid); }},
                               {label : 'Permissions', id : 'permissions', onLoad : function(cid, eid) { require('common/users.js'); permissions(cid, eid); }}
                               ],
        'Monitoring'       : []
    },
};

// Details corresponds to element of list
// Key of this map is id of the list (grid)
// onLoad handlers are called with params (content_container_id, selected_elem_id)
var details_def = {
    'iaas_list' : { tabs: 
        [   { label  : 'Overview', 
                id     : 'iaas_detail_overview'},
            { label  : 'Hypervisor', 
                id     : 'iass_detail_hyp',
                onLoad : load_iaas_detail_hypervisor },
        ],
    },
    'customers_list' : { tabs: 
        [ { label  : 'Overview',
               id     : 'customer_detail_overview',
               onLoad : customers.load_details },
            { label  : 'Services',
               id     : 'customer_detail_services',
               onLoad : customers.load_services },
            { label  : 'Infos',
               id    : 'customer_detail_infos',
               onLoad : customers.load_infos },
             
        ],
     },
    'service_template_list'   : { onSelectRow : load_service_template_details },
    'hosting_policy_list'     : { onSelectRow : load_policy_details },
    'storage_policy_list'     : { onSelectRow : load_policy_details },
    'network_policy_list'     : { onSelectRow : load_policy_details },
    'system_policy_list'      : { onSelectRow : load_policy_details },
    'scalability_policy_list' : { onSelectRow : load_policy_details },
};

function reloadServices () {
    // Trigger click callback wich relaod grid content and dynamic menu
    $('#menuhead_Services').click();
}
