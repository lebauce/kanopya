require('KIM/iaas.js');
require('KIM/customers.js');
require('servicemenudefinition.js');
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
    'Services'          : getServiceMenuDefinition('cluster'),
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' :  [
                               {label : 'Users', id : 'users', onLoad : function(cid, eid) { require('KIO/users.js'); usersList(cid, eid); }},
                               {label : 'Groups', id : 'groups',onLoad : function(cid, eid) { require('KIO/users.js'); groupsList(cid, eid); }},
                               {label : 'Permissions', id : 'permissions', onLoad : function(cid, eid) { require('KIO/users.js'); permissions(cid, eid); }}
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
                             
                      ],
                  },
};

function reloadServices () {
    // Trigger click callback wich relaod grid content and dynamic menu
    $('#menuhead_Services').click();
}
