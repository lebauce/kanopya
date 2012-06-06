// each link will show the div with id "view_<id>" and hide all div in "#view-container"
// onLoad handlers are called with params (content_container_id)
var mainmenu_def = {
    'Infrastructure'    : {
        'Compute' : [{label : 'Overview', id : 'compute_overview'},
                     {label : 'Hosts', id : 'hosts'}],
        'Storage' : [{label : 'Overview', id : 'storage_overview'}],
        'IaaS'    : [{label : 'IaaS', id : 'iaas', onLoad : load_iaas_content},
                     {label : 'Log & Event', id : 'logs'}],
        'Network' : [],
        'System'  : [],
    },
    'Business'          : {
        'Policies'   : [],
        'Services Templates' : [],
        'Customers'  : [{label: 'Overview', id: 'customers_overview'},
                        {label: 'Customers', id: 'customers', onLoad: customersList},
                        {label: 'Cost Model', id: 'cost_model'}    ]
    },
    'Services'           : {
    
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' : [],
        'Monitoring'       : []
    },
};

// Details corresponds to element of list
// Key of this map is id of the list (grid)
// onLoad handlers are called with params (content_container_id, selected_elem_id)
var details_def = {
        'iaas_list' : {
            tabs : [{label : 'Overview', id : 'iaas_detail_overview'},
                    {label : 'Hypervisor', id : 'iass_detail_hyp', onLoad : load_iaas_detail_hypervisor}],
        }
};

