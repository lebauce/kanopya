// each link will show the div with id "view_<link_name>" and hide all div in "#view-container"
var mainmenu_def = {
    'Infrastructure'    : {
        'Clusters' : [
                     {label : 'Overview', id : 'overview'},
                     {label : 'Hosts', id : 'hosts'}],
        'Connectors' : [''],
    },
    'Administration'    : {
        'Kanopya'          : [],
        'Right Management' : [],
        'Monitoring'       : [],
    },
    'Services'   : {
        //onLoad : load_services,
        masterView : [
                      {label : 'Overview', id : 'services_overview'},
                      {label : 'Services', id : 'services_list', onLoad : servicesList}
                      ],
        json : {url         : '/api/externalcluster',
                label_key   : 'externalcluster_name',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : loadServicesOverview},
                               {label : 'Configuration', id : 'service_configuration', onLoad : loadServicesConfig},
                               {label : 'Ressources', id : 'service_ressources', onLoad : loadServicesRessources}
                               ]
                }
    },
    'Hosts'   : {
        json : {url        : '/api/host',
                label_key   : 'host_hostname',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : displayJSON},
                               {label : 'Hosts', id : 'service_hosts'}
                               ]
                }
    }
};

var details_def = {
        'services_list' : { link_to_menu : 'yes', label_key : 'externalcluster_name'}
};

// Placeholder handler wich display elem json from rest api
function displayJSON (container_id, elem_id) {
    $.getJSON('api/entity/'+elem_id, function (data) {
        $('#'+container_id).append('<div>' + JSON.stringify(data) + '</div>');
    });
}

// To move on specific service file
function servicesList (container_id, elem_id) {
    
    function createAddServiceButton() {
        $.validator.addMethod("regex", function(value, element, regexp) {
            var re = new RegExp(regexp);
            return this.optional(element) || re.test(value);
        }, "Please check your input");
     
        var newServicePK = undefined;
     
        function createScomDialog(data) {
            var scom_fields = {
                scom_ms_name        : {
                    label   : 'Root Management Server FQDN'
                },
                scom_usessl         : {
                    label   : 'Use SSL ?',
                    type    : 'checkbox'
                },
                service_provider_id : {
                    label   : '',
                    type    : 'hidden',
                    value   : newServicePK
                }
            };
            var scom_opts   = {
                title       : 'Add a SCOM',
                name        : 'scom',
                skippable   : true,
                fields      : scom_fields
            }
            new ModalForm(scom_opts).start();
        }
        
        function createADDialog() {
            var ad_fields   = {
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
                service_provider_id : {
                    label   : '',
                    type    : 'hidden',
                    value   : newServicePK
                }
            };
            var ad_opts     = {
                title       : 'Add an Active Directory',
                name        : 'active_directory',
                skippable   : true,
                fields      : ad_fields,
                callback    : createScomDialog
            };
            new ModalForm(ad_opts).start();
        }
     
        var service_fields  = {
                externalcluster_name    : {
                    label   : 'Name'
                },
                externalcluster_desc    : {
                    label   : 'Description',
                    type    : 'textarea'
                }
        };
        var service_opts    = {
            title       : 'Add a Service',
            name        : 'externalcluster',
            fields      : service_fields,
            callback    : function(data) {
                newServicePK = data.pk;
                createADDialog();
            }
        };
                    
        var button = $("<button>", {html : 'Add a service'});
        button.bind('click', function() {
            new ModalForm(service_opts).start();
        });   
        $('#' + container_id).append(button);
    };
    
    var container = $('#' + container_id);
    
    create_grid(container_id, 'services_list',
                ['ID','Name', 'State'],
                [ 
                 {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'externalcluster_name',index:'service_name', width:200},
                 {name:'externalcluster_state',index:'service_state', width:90,},
                 ]);
    reload_grid('services_list', '/api/externalcluster');
    
    createAddServiceButton();
}