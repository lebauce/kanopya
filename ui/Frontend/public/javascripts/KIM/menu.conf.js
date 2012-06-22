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
                                { label : 'Scalability', id : 'scalability_policy', onLoad : load_policy_content } ],
        'Service templates' : [ { label : 'Service templates', id : 'service_template', onLoad : load_service_template_content } ],
        'Accounting' : []
    },
    'Services' : {
    },
    'Administration' : {
        'Kanopya'          : [],
        'Right Management' : [],
        'Monitoring'       : []
    },
};

// Details corresponds to element of list
// Key of this map is id of the list (grid)
// onLoad handlers are called with params (content_container_id, selected_elem_id)
var details_def = {
    'iaas_list' : [ { label : 'Overview',   id : 'iaas_detail_overview'},
                    { label : 'Hypervisor', id : 'iass_detail_hyp', onLoad : load_iaas_detail_hypervisor } ],
    'service_template_list'   : { onSelectRow : load_service_template_details },
    'hosting_policy_list'     : { onSelectRow : load_policy_details },
    'storage_policy_list'     : { onSelectRow : load_policy_details },
    'network_policy_list'     : { onSelectRow : load_policy_details },
    'system_policy_list'      : { onSelectRow : load_policy_details },
    'scalability_policy_list' : { onSelectRow : load_policy_details },
};

