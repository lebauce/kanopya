// KIM services

require('modalform.js');
require('common/service_common.js');

function servicesList (container_id, elem_id) {
    var container = $('#' + container_id);
    
    create_grid( {
        url: '/api/cluster',
        content_container_id: container_id,
        grid_id: 'services_list',
        afterInsertRow: function (grid, rowid, rowdata, rowelem) {
            addServiceExtraData(grid, rowid, rowdata, rowelem, '');
        },
        rowNum : 25,
        colNames: [ 'ID', 'Name', 'State', 'Rules State', 'Node Number', 'other' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'cluster_name', index: 'service_name', width: 200 },
            { name: 'cluster_state', index: 'service_state', width: 90, formatter:StateFormatter },
            { name: 'rulesstate', index : 'rulesstate' },
            { name: 'node_number', index: 'node_number', width: 150 }
        ],
        elem_name   : 'service',
        details     : { link_to_menu : 'yes', label_key : 'cluster_name'}
    });
    
    //$("#services_list").on('gridChange', reloadServices);
    
    //createAddServiceButton(container);
}