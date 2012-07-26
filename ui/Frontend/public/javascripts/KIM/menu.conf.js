require('KIM/iaas.js');
require('common/users.js');
require('KIM/customers.js');
require('KIM/servicetemplates.js');
require('KIM/policies.js');

// each link will show the div with id "view_<id>" and hide all div in "#view-container"
// onLoad handlers are called with params (content_container_id)
var mainmenu_def = {
    'Infrastructure' : {
        'Compute' : [
            { label : 'Overview', id : 'compute_overview'},
            { label : 'Hosts', id : 'hosts', onLoad : function(cid) { require('KIM/hosts.js'); hosts_list(cid, '2'); } },
            { label : 'UCS', id : 'ucs', onLoad : function(cid) { require('KIM/ucs.js'); ucs_list(cid); } }
        ],
        'Storage' : [
            { label : 'Overview', id : 'storage_overview'},
            { label : 'NetApp', id : 'storage_netapp', onLoad : function(cid) { require('KIM/netapp.js'); netapp_list(cid); } }
        ],
        'IaaS'    : [ { label : 'IaaS', id : 'iaas', onLoad : load_iaas_content} ],
        'Network' : [
            { label : 'Overview', id : 'network_overview' },
            { label : 'Networks', id : 'network_vlans', onLoad : function(cid) { require('KIM/networks.js'); networks_list(cid); } },
            { label : 'PoolIPs', id : 'network_poolips', onLoad : function(cid) { require('KIM/poolips.js'); poolips_list(cid); } }
        ],
        'System'  : [],
    },
    'Business' : {
        'Policies'          : [ { label : 'Hosting',        id : 'hosting_policy',          onLoad : load_policy_content },
                                { label : 'Storage',        id : 'storage_policy',          onLoad : load_policy_content },
                                { label : 'Network',        id : 'network_policy',          onLoad : load_policy_content },
                                { label : 'System',         id : 'system_policy',           onLoad : load_policy_content },
                                { label : 'Scalability',    id : 'scalability_policy',      onLoad : load_policy_content },
                                { label : 'Billing',        id : 'billing_policy',          onLoad : load_policy_content },
                                { label : 'Orchestration',  id : 'orchestration_policy',    onLoad : load_policy_content }],
        'Services'          : [ { label : 'Services',  id : 'service_template', onLoad : load_service_template_content } ],
        'Customers'         : [ { label : 'Customers', id : 'customers', onLoad: customers.load_content }]
    },
    'Services'     : {
        masterView : [
                      {label : 'Service instances', id : 'services_overview', onLoad : function(cid) { require('KIM/services.js'); servicesList(cid); }}
                      ],
        jsontree : {
                level1_url         : '/api/servicetemplate',
                level1_label_key   : 'service_name',
                level2_url         : '/api/cluster',
                level2_label_key   : 'cluster_name',
                level2_filter       : function(elem) { return servicesListFilter(elem); }, 
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : function(cid, eid) { require('common/service_dashboard.js'); loadServicesOverview(cid, eid);}},
                               {label : 'Details', id : 'service_details', onLoad : function(cid, eid) { require('KIM/services_details.js'); loadServicesDetails(cid, eid);}},
                               {label : 'Configuration', id : 'service_configuration', onLoad : function(cid, eid) { require('KIM/services_config.js'); loadServicesConfig(cid, eid);}},
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
                               {label : 'Users', id : 'users', onLoad : users.load_content },
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
     'users_list' : { tabs: 
        [ { label  : 'Overview',
               id  : 'user_detail_overview',
               onLoad : users.load_details },
            { label  : 'Profiles',
               id     : 'user_detail_profiles',
               onLoad : users.load_profiles },
        ],
     },
    'service_template_list'    : { onSelectRow : load_service_template_details },
};

function reloadServices () {
    // Trigger click callback wich relaod grid content and dynamic menu
    $('#menuhead_Services').click();
}

function filterDisplayByProfile () {
    // Get username of current logged user :
    var username = '';
    var userid;
    var profileid;
    $.ajax({
        async   : false,
        url     : '/me',
        type    : 'GET',
        success : function(data) {
            username = data.username;
        }
    });
    // Get profile list for the username :
    $.ajax({
        async   : false,
        url     : '/api/user?user_login=' + username,
        type    : 'GET',
        success : function(data) {
            userid = data[0].user_id;
        }
    });
    $.ajax({
        async   : false,
        url     : '/api/userprofile?user_id=' + userid,
        tyepe   : 'GET',
        success : function(data) {
            profileid = data[0].profile_id;
        }
    });
    // Filter UI display by profile :
    switch (profileid) {
        case 1:
            
        break;
    }
}

filterDisplayByProfile();
