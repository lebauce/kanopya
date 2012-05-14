// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"
var mainmenu_def = {
    'Infrastructure'    : {
        'Compute' : [{label : 'Overview', id : 'compute_overview'},
                     {label : 'Hosts', id : 'hosts'}],
        'Storage' : [{label : 'Overview', id : 'storage_overview'}],
        'IaaS'    : [{label : 'IaaS', id : 'iaas'},
                     {label : 'Log & Event', id : 'logs'}],
        'Network' : [],
        'System'  : [],
    },
    'Business'          : {
        'Profiles'   : [],
        'Accounting' : []
    },
    'Services'           : {
    
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' : [],
        'Monitoring'       : []
    },
};