require('KIM/iaas.js');
require('common/users.js');
require('KIM/customers.js');
require('KIM/servicetemplates.js');
require('KIM/policies.js');

// Get the kanopya cluster id
$.getJSON("/api/cluster?cluster_name=Kanopya", function (data) {
    kanopya_cluster = data[0].pk;

    // Get the PhysicalHoster id
    $.getJSON("/api/cluster/" + kanopya_cluster + "/components?expand=component_type&component_type.component_name=Physicalhoster", function (data) {
        physical_hoster = data[0].pk;
    });
});

var service_list_url = '/api/cluster';

// If the logged user is a customer, filter the list of service
var customer_filter = '';
if (current_user.profiles.length == 1 && current_user.profiles[0].profile_name === "Customer") {
    service_list_url += '?user_id=' + current_user.user_id;
}

// each link will show the div with id "view_<id>" and hide all div in "#view-container"
// onLoad handlers are called with params (content_container_id)
var mainmenu_def = {
    'Infrastructure' : {
        'Compute' : [
            { label : 'Hosts', id : 'hosts', onLoad : function(cid) { require('KIM/hosts.js'); hosts_list(cid, physical_hoster); } },
            { label : 'UCS',   id : 'ucs',   onLoad : function(cid) { require('KIM/ucs.js'); ucs_list(cid); } }
        ],
        'Storage' : [
            { label : 'Linux NAS', id : 'storage_linux', onLoad : function(cid) { require('KIM/storage.js'); linuxnas_list(cid); } },
            { label : 'NetApp', id : 'storage_netapp', onLoad : function(cid) { require('KIM/storage.js'); netapp_list(cid); } }
        ],
        'IaaS'    : [
            { label : 'IaaS', id : 'iaas', onLoad : load_iaas_content}
        ],
        'Network' : [
            { label : 'Networks',               id : 'network_networks', onLoad : function(cid) { require('KIM/networks.js'); networks_list(cid); } },
            { label : 'VLANs',                  id : 'network_vlans',    onLoad : function(cid) { require('KIM/vlans.js'); vlans_list(cid); } },
            { label : 'PoolIPs',                id : 'network_poolips',  onLoad : function(cid) { require('KIM/poolips.js'); poolips_list(cid); } },
            { label : 'Network Configurations', id : 'network_netconf',  onLoad : function(cid) { require('KIM/netconf.js'); netconfs_list(cid); } }
        ],
        'System'  : [
            { label : 'Master Images',  id : 'master_image',  onLoad : function(cid) { require('KIM/masterimage.js'); masterimagesMainView(cid); } },
            { label : 'System Images',  id : 'system_images', onLoad : function(cid) { require('KIM/systemimage.js'); systemimagesMainView(cid); } },
            { label : 'Kernels',        id : 'kernels',       onLoad : function(cid) { require('KIM/kernel.js'); Kernel.list(cid); } }
        ]
    },
    'Business' : {
        'Policies'  : [
            { label : 'Hosting',        id : 'hosting_policy',       onLoad : load_policy_content, icon : "hosting" },
            { label : 'Storage',        id : 'storage_policy',       onLoad : load_policy_content, icon : "storage" },
            { label : 'Network',        id : 'network_policy',       onLoad : load_policy_content, icon : "network" },
            { label : 'System',         id : 'system_policy',        onLoad : load_policy_content, icon : "system" },
            { label : 'Scalability',    id : 'scalability_policy',   onLoad : load_policy_content, icon : "scalability" },
            { label : 'Billing',        id : 'billing_policy',       onLoad : load_policy_content, icon : "metering" },
            { label : 'Orchestration',  id : 'orchestration_policy', onLoad : load_policy_content, icon : "workload" }
        ],
        'Services'  : [
            { label : 'Services',  id : 'service_template', onLoad : load_service_template_content }
        ],
        'Customers' : [
            { label : 'Customers', id : 'customers', onLoad: customers.load_content }
        ]
    },
    'Services'     : {
        masterView : [
            { label : 'Service instances', id : 'services_overview', onLoad : function(cid) { require('KIM/services.js'); servicesList(cid); } }
        ],
        jsontree : {
            level1_url       : '/api/servicetemplate',
            level1_label_key : 'service_name',
            level2_url       : service_list_url,
            level2_label_key : 'cluster_name',
            level2_filter    : function(elem) { return servicesListFilter(elem); }, 
            id_key           : 'pk',
            submenu          : [
                { label : 'Overview',        id : 'service_overview',      onLoad : function(cid, eid) { require('common/service_dashboard.js'); loadServicesOverview(cid, eid); }, icon : 'dashboard' },
                { label : 'Details',         id : 'service_details',       onLoad : function(cid, eid) { require('KIM/services_details.js'); loadServicesDetails(cid, eid); }, icon : 'search' },
                { label : 'Configuration',   id : 'service_configuration', onLoad : function(cid, eid) { require('KIM/services_config.js'); loadServicesConfig(cid, eid); }, icon : 'system' },
                { label : 'Resources',       id : 'service_resources',     onLoad : function(cid, eid) { require('KIM/services.js'); loadServicesResources(cid, eid); }, icon : 'resources' },
                { label : 'Monitoring',      id : 'service_monitoring',    onLoad : function(cid, eid) { require('common/service_monitoring.js'); loadServicesMonitoring(cid, eid); }, icon : 'monitoring' },
                { label : 'Rules',           id : 'service_rules',         onLoad : function(cid, eid) { require('common/service_rules.js'); loadServicesRules(cid, eid); }, icon : 'rules' },
                { label : 'Events & Alerts', id : 'events_alerts',         onLoad : function(cid, eid) { require('common/service_eventsalerts.js'); loadServiceEventsAlerts(cid, eid); }, icon : 'alert' },
                { label : 'Billing',         id : 'billing',               onLoad : function(cid, eid) { require('KIM/billing.js'); billinglist(cid, eid); }, icon : 'metering' }
            ]
        }
    },
    'Administration'    : {
        'Kanopya'          : [
            { label : 'Overview',        id : 'service_overview',      onLoad : function(cid, eid) { require('common/service_dashboard.js'); loadServicesOverview(cid, kanopya_cluster); }, icon : 'dashboard' },
            { label : 'Details',         id : 'service_details',       onLoad : function(cid, eid) { require('KIM/services_details.js'); loadServicesDetails(cid, kanopya_cluster); }, icon : 'search' },
            { label : 'Configuration',   id : 'service_configuration', onLoad : function(cid, eid) { require('KIM/services_config.js'); loadServicesConfig(cid, kanopya_cluster); }, icon : 'system' },
            { label : 'Resources',       id : 'service_resources',     onLoad : function(cid, eid) { require('KIM/services.js'); loadServicesResources(cid, kanopya_cluster); }, icon : 'resources' },
            { label : 'Monitoring',      id : 'service_monitoring',    onLoad : function(cid, eid) { require('common/service_monitoring.js'); loadServicesMonitoring(cid, kanopya_cluster); }, icon : 'monitoring' },
            { label : 'Rules',           id : 'service_rules',         onLoad : function(cid, eid) { require('common/service_rules.js'); loadServicesRules(cid, kanopya_cluster); }, icon : 'rules' },
            { label : 'Events & Alerts', id : 'events_alerts',         onLoad : function(cid, eid) { require('common/service_eventsalerts.js'); loadServiceEventsAlerts(cid, kanopya_cluster); }, icon : 'alert' },
        ],
        'Right Management' : [
            { label : 'Users',       id : 'users',       onLoad : users.load_content },
            { label : 'Groups',      id : 'groups',      onLoad : function(cid, eid) { require('common/users.js'); groupsList(cid, eid); } },
            { label : 'Permissions', id : 'permissions', onLoad : function(cid, eid) { require('common/users.js'); permissions(cid, eid); } }
        ]
    }
};

// Details corresponds to element of list
// Key of this map is id of the list (grid)
// onLoad handlers are called with params (content_container_id, selected_elem_id)
var details_def = {
    'customers_list' : {
        tabs: [
            { label : 'Overview', id : 'customer_detail_overview', onLoad : customers.load_details },
            { label : 'Services', id : 'customer_detail_services', onLoad : customers.load_services },
            { label : 'Infos',    id : 'customer_detail_infos',    onLoad : customers.load_infos }
        ]
     },
    'service_template_list' : {
        onSelectRow : load_service_template_details
    }
};

function reloadServices () {
    // Trigger click callback wich relaod grid content and dynamic menu
    $('#menuhead_Services').click();
}
