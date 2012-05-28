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
        json : {url        : '/api/externalcluster',
                label_key   : 'externalcluster_name',
                id_key      : 'pk',
                submenu     : [
                               {label : 'Overview', id : 'service_overview', onLoad : displayJSON},
                               {label : 'Hosts', id : 'service_hosts'}
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


// Placeholder handler wich display elem json from rest api
function displayJSON (container_id, elem_id) {
    $.getJSON('api/entity/'+elem_id, function (data) {
        $('#'+container_id).append('<div>' + JSON.stringify(data) + '</div>');
    });
}
