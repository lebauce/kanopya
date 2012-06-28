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

            // Service name
            $.ajax({
                url     : '/api/cluster/' + rowid + '/service_template',
                type    : 'GET',
                success : function(serv_template) {
                    $(grid).setCell(rowid, 'service_template_name', serv_template.service_name);
                },
                error : function ()  {
                    $(grid).setCell(rowid, 'service_template_name', 'internal');
                }
            });
        },
        rowNum : 25,
        colNames: [ 'ID', 'Service', 'Instance Name', 'State', 'Rules State', 'Node Number' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'service_template_name', index: 'service_template_name', width: 200 },
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

function loadServicesRessources (container_id, elem_id) {
    var loadServicesRessourcesGridId = 'service_ressources_list_' + elem_id;
    var nodemetricrules;

    $.ajax({
        url     : '/api/nodemetricrule?nodemetric_rule_service_provider_id=' + elem_id,
        success : function(data) {
            nodemetricrules   = data;
        }
    });
    create_grid( {
        url: '/api/node?inside_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesRessourcesGridId,
        grid_class: 'service_ressources_list',
        rowNum : 25,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            addRessourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, elem_id, '');

            // Core and ram info
            var host_id  = $(grid).getCell(rowid, 'host_id');
            $.ajax({
                url     : '/api/host/' + host_id,
                type    : 'GET',
                success : function(data) {
                    $(grid).setCell(rowid, 'host_core', data.host_core);
                    $(grid).setCell(rowid, 'host_ram', data.host_ram + 'B');
                }
            });
        },
        colNames: [ 'id', 'host id', 'State', 'Hostname', 'Core', 'Ram', 'Rules State' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'host_id', index: 'host_id', hidden: true},
            { name: 'node_state', index: 'node_state', width: 90, formatter: StateFormatter },
            { name: 'externalnode_hostname', index: 'node_hostname', width: 200 },
            { name: 'host_core', index: 'host_core' },
            { name: 'host_ram', index: 'host_ram' },
            { name: 'rulesstate', index: 'rulestate' }
        ],
        details : {
            tabs : [
                        { label : 'Rules', id : 'rules', onLoad : function(cid, eid) { node_rules_tab(cid, eid, elem_id); } },
                    ],
            title : { from_column : 'externalnode_hostname' }
        },
        action_delete: 'no',
    } );

    //createUpdateNodeButton($('#' + container_id), elem_id, $('#' + loadServicesRessourcesGridId));
}