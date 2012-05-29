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
 
    var newServicePK = undefined;
 
    function createScomDialog(data) {
        var scom_opts   = {
            title       : 'Add a SCOM',
            name        : 'scom',
            skippable   : true,
            fields      : {
                scom_ms_name        : {
                    label   : 'Root Management Server FQDN'
                },
                scom_usessl         : {
                    label   : 'Use SSL ?',
                    type    : 'checkbox',
                    value   : false
                },
                service_provider_id : {
                    label   : '',
                    type    : 'hidden',
                    value   : newServicePK
                }
            }
        }
        new ModalForm(scom_opts).start();
    }
    
    function createADDialog() {
        var ad_opts = {
            title       : 'Add an Active Directory',
            name        : 'active_directory',
            skippable   : true,
            fields      : {
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
                    type    : 'checkbox',
                    value   : false
                },
                service_provider_id : {
                    label   : '',
                    type    : 'hidden',
                    value   : newServicePK
                }
            },
            callback    : createScomDialog
        };
        new ModalForm(ad_opts).start();
    }
 
    var service_opts    = {
        title       : 'Add a Service',
        name        : 'externalcluster',
        fields      : {
            externalcluster_name    : {
                label   : 'Name'
            },
            externalcluster_desc    : {
                label   : 'Description',
                type    : 'textarea'
            }
        },
        callback    : function(data) {
            newServicePK = data.pk;
            createADDialog();
        }
    };
                
    var button = $("<button>", {html : 'Add form'});
    button.bind('click', function() {
        new ModalForm(service_opts).start();
    });   
    $('#' + container_id).append(button);
};