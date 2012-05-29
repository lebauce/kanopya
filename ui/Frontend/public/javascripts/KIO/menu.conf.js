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
    var container = $('#' + container_id);
    
    create_grid(container_id, 'services_list',
                ['ID','Name', 'State'],
                [ 
                 {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'externalcluster_name',index:'service_name', width:200},
                 {name:'externalcluster_state',index:'service_state', width:90,},
                 ]);
    reload_grid('services_list', '/api/externalcluster');
}
