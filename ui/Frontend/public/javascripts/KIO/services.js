
require('modalform.js');
require('common/service_common.js');
require('common/formatters.js');
require('KIO/services_config.js');

function createAddServiceButton(container) {
    var service_fields  = {
        externalcluster_name    : {
            label   : 'Name',
            help    : "Name which identify your service"
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
        beforeSubmit: function() {
            setTimeout(function() {
                var dialog = $("<div>", { id : "waiting_default_insert", title : "Initializing configuration", text : "Please wait..." });
                dialog.css('text-align', 'center');
                dialog.appendTo("body").dialog({
                    draggable   : false,
                    resizable   : false,
                    title       : ""
                });
                $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
            }, 10);
        },
        callback    : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
            createmanagerDialog('directory_service_manager', data.pk, function() {
                createmanagerDialog('collector_manager', data.pk, function() {
                    reloadServices();
                }, true);
            }, true);
        },
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a service'}).button({ icons : { primary : 'ui-icon-plusthick' } });
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    });   
    $(container).append(button);
};

function servicesList (container_id, elem_id) {
    var container = $('#' + container_id);
    
    create_grid( {
        url: '/api/externalcluster?connectors.connector_id=', // Only list externalcluster without connector
        content_container_id: container_id,
        grid_id: 'services_list',
        afterInsertRow: function (grid, rowid, rowdata, rowelem) {
            addServiceExtraData(grid, rowid, rowdata, rowelem, 'external');
        },
        rowNum : 25,
        colNames: [ 'ID', 'Name', 'Rules State', 'Node Number' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'externalcluster_name', index: 'externalcluster_name', width: 200 },
            { name: 'rulesstate', index : 'rulesstate' },
            { name: 'node_number', index: 'node_number', width: 150 }
        ],
        elem_name   : 'service',
        details     : { link_to_menu : 'yes', label_key : 'externalcluster_name'},
    });
    
    $("#services_list").on('gridChange', reloadServices);
    
    createAddServiceButton(container);
}

function createUpdateNodeButton(container, elem_id, grid) {
    var button = $("<button>", { text : 'Update Nodes' }).button({ icons : { primary : 'ui-icon-refresh' } });
    // Check if there is a configured directory service
    var manager = isThereAManager(elem_id, 'directory_service_manager');
    if (manager) {
        $(button).bind('click', function(event) {
            require('common/general.js');
            callMethodWithPassword({
                    login        : manager.ad_user,
                    dialog_title : "Update service nodes",
                    url          : '/api/externalcluster/' + elem_id + '/updateNodes',
                    success      : function(data) {
                        $(grid).trigger("reloadGrid");
                    }
            });
        });
    } else {
        $(button).attr('disabled', 'disabled');
        $(button).attr('title', 'Your service must be connected with a directory.')
    }
    // Finally, append the button in the DOM tree
    $(container).append(button);
}

function scoConfigurationDialog(elem_id, sco_id) {
  console.log(sco_id);
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
        url: '/api/externalnode?service_provider_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesRessourcesGridId,
        grid_class: 'service_ressources_list',
        rowNum : 25,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            addRessourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, elem_id, 'external');
        },
        colNames: [ 'id', 'State', 'Hostname', 'Rules State' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'externalnode_state', index: 'externalnode_state', width: 90, formatter: StateFormatter },
            { name: 'externalnode_hostname', index: 'externalnode_hostname', width: 200 },
            { name: 'rulesstate', index: 'rulestate' }
        ],
        details : {
            tabs : [
                        { label : 'Rules', id : 'rules', onLoad : function(cid, eid) { node_rules_tab(cid, eid, elem_id); } },
                    ],
            title : { from_column : 'externalnode_hostname' }
        },
    } );

    createUpdateNodeButton($('#' + container_id), elem_id, $('#' + loadServicesRessourcesGridId));
    //reload_grid(loadServicesRessourcesGridId,'/api/externalnode?outside_id=' + elem_id);
    $('service_ressources_list').jqGrid('setGridWidth', $(container_id).parent().width()-20);
}
