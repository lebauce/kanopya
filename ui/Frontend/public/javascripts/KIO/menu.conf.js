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
        'Right Management' :  [
                               {label : 'Users', id : 'users', onLoad : loadUsers},
                               {label : 'Rights', id : 'rights'}
                               ],
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
                               {label : 'Ressources', id : 'service_ressources', onLoad : loadServicesRessources},
                               {label : 'Monitoring', id : 'service_monitoring', onLoad : loadServicesMonitoring},
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

function reloadServices () {
    // Trigger click callback wich relaod grid content and dynamic menu
    $('#menuhead_Services').click();
}

// To move on specific service file
function servicesList (container_id, elem_id) {
    
    function createAddServiceButton(cid) {
        $.validator.addMethod("regex", function(value, element, regexp) {
            var re = new RegExp(regexp);
            return this.optional(element) || re.test(value);
        }, "Please check your input");
     
        var newServicePK = undefined;
        
        var chooseMonitoringModal = new ModalForm({
            name            : 'connector',
            skippable       : true,
            fields          : {
                connector_type_id   : {
                    label   : 'Step 3 of 3 : Choose a monitoring service',
                    display : 'connector_name',
                    cond    : '?connector_category=MonitoringService'
                }
            },
            beforeSubmit    : monitoringServiceCreation
        });
        
        var chooseDirectoryModal = new ModalForm({
            name            : 'connector',
            skippable       : true,
            title           : 'Step 2 of 3 : Choose a directory service',
            fields          : {
                connector_type_id   : {
                    label   : 'Choose a directory service',
                    display : 'connector_name',
                    cond    : '?connector_category=DirectoryService'
                }
            },
            callback        : function() { chooseMonitoringModal.start() },
            beforeSubmit    : directoryServiceCreation
        });
        
        function monitoringServiceCreation(arr, $form, opts, dialog) {
            for (field in arr) if (arr.hasOwnProperty(field)) {
                if (arr[field].name === 'connector_type_id') {
                    if (arr[field].value == 2) { // Then must open SCOM's form
                        dialog.closeDialog();
                        createScomDialog();
                    }
                }
            }
            return false;
        }
     
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
                title       : 'Step 3 of 3 : Add a SCOM',
                name        : 'scom',
                skippable   : true,
                fields      : scom_fields,
                callback    : reloadServices,
                cancel      : function() { chooseMonitoringModal.start(); }
            }
            new ModalForm(scom_opts).start();
        }
        
        function directoryServiceCreation(arr, $form, opts, dialog) {
            for (field in arr) if (arr.hasOwnProperty(field)) {
                if (arr[field].name === 'connector_type_id') {
                    if (arr[field].value == 1) { // Then must open Active directory's form
                        dialog.closeDialog();
                        createADDialog();
                    }
                }
            }
            return false;
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
                title       : 'Step 2 of 3 : Add an Active Directory',
                name        : 'activedirectory',
                skippable   : true,
                fields      : ad_fields,
                callback    : function() { chooseMonitoringModal.start(); },
                cancel      : function() { chooseDirectoryModal.start(); }
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
            title       : 'Step 1 of 3 : Add a Service',
            name        : 'externalcluster',
            fields      : service_fields,
            callback    : function(data) {
                newServicePK = data.pk;
                chooseDirectoryModal.start();
            }
        };
                    
        var button = $("<button>", {html : 'Add a service'});
        button.bind('click', function() {
            new ModalForm(service_opts).start();
        });   
        $('#' + cid).append(button);
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
    
    createAddServiceButton(container_id);
}

