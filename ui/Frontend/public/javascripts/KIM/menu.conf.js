require('KIM/iaas.js');
require('KIM/customers.js');
// each link will show the div with id "view_<id>" and hide all div in "#view-container"
// onLoad handlers are called with params (content_container_id)
var mainmenu_def = {
    'Infrastructure'    : {
        'Compute' : [{label : 'Overview', id : 'compute_overview'},
                     {label : 'Hosts', id : 'hosts'}],
        'Storage' : [{label : 'Overview', id : 'storage_overview'}],
        'IaaS'    : [{label : 'IaaS', id : 'iaas', onLoad : load_iaas_content },
                     {label : 'Log & Event', id : 'logs'}],
        'Network' : [],
        'System'  : [],
    },
    'Business'          : {
        'Policies'   : [],
        'Services Templates' : [],
        'Customers'  : [{label: 'Customers', id: 'customers', onLoad: customers.load_content }]
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
        'iaas_list' : [ { label  : 'Overview', 
                          id     : 'iaas_detail_overview'},
                        { label  : 'Hypervisor', 
                          id     : 'iass_detail_hyp',
                          onLoad : load_iaas_detail_hypervisor },
                      ],
        'customers_list' : [ { label  : 'Overview',
                               id     : 'customer_detail_overview',
                               onLoad : customers.load_details },
                             
                      ],
};

