// each link will show the div with id "view_<id>" and hide all div in "#view-container"
// onLoad handlers are called with params (content_container_id)
var mainmenu_def = {
    'Infrastructure'    : {
        'Compute' : [{label : 'Overview', id : 'compute_overview', onLoad : func},
                     {label : 'Hosts', id : 'hosts'}],
        'Storage' : [{label : 'Overview', id : 'storage_overview'}],
        'IaaS'    : [{label : 'IaaS', id : 'iaas', onLoad : load_iaas_content},
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

// Details corresponds to element of list
// Key of this map is id of the list (grid)
// onLoad handlers are called with params (content_container_id, selected_elem_id)
var details_def = {
        'iaas_list' : [{label : 'Overview', id : 'iaas_detail_overview'},
                       {label : 'Hypervisor', id : 'iass_detail_hyp', onLoad : load_iaas_detail_hypervisor},
                      ],
};

function func(container_id) {    
    $.validator.addMethod("regex", function(value, element, regexp) {
        var re = new RegExp(regexp);
        return this.optional(element) || re.test(value);
    }, "Please check your input");
                
    var button = $("<button>", {html : 'Add form'});
    button.bind('click', function() {
        var theform = new ModalForm({
            title   : 'Add an External Cluster',
            name    : 'externalcluster',
            fields  : {
                externalcluster_name    : {
                    label   : 'Name'
                },
                externalcluster_desc    : {
                    label   : 'Description',
                    type    : 'textarea'
                }
            }
        });
    });   
    $('#' + container_id).append(button);
    
    button = $("<button>", {html : 'Add active directory'});
    button.bind('click', function() {
        var theform = new ModalForm({
            title   : 'Add an Active Directory',
            name    : 'active_directory', 
            fields  : {
                ad_host             : {
                    label   : 'Domain controller name'
                },
                ad_nodes_base_dn    : {
                    label   : 'Nodes container domain name'
                },
                ad_user             : {
                    label   : 'User@domain'
                },
                ad_pwd              : {
                    label   : 'Password',
                    type    : 'password'
                },
                ad_usessl           : {
                    label   : 'Use SSL ?',
                    type    : 'checkbox'
                },
                serviceprovider_id : {
                    label   : '',
                    type    : 'hidden',
                    value   : '119'
                }
            }
        });
    });
    $('#' + container_id).append(button);
};