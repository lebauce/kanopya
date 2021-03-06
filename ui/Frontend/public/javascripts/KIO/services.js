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
                    dialogClass : "no-close",
                    resizable   : false,
                    title       : ""
                });
                $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
            }, 10);
        },
        callback    : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
            createmanagerDialog('DirectoryServiceManager', data.pk, function() {
                createmanagerDialog('CollectorManager', data.pk, function() {
                    reloadServices();
                }, true);
            }, true);
        },
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a service', id : 'add-service-button'}).button({ icons : { primary : 'ui-icon-plusthick' } });
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    });
    container.append(button);
};

function servicesList (container_id, elem_id) {
    var action_buttons_container = $('#' + container_id).prevAll('.action_buttons');
    createAddServiceButton(action_buttons_container);

    // Only list externalcluster without connector
    create_grid( {
        url: '/api/externalcluster?expand=nodes&components.component_id=',
        content_container_id: container_id,
        grid_id: 'services_list',
        afterInsertRow: function (grid, rowid, rowdata, rowelem) {
            addServiceExtraData(grid, rowid, rowdata, rowelem);
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
        multiselect : true,
        multiactions : {
            multiDelete : {
                label   : 'Delete service(s)',
                action  : removeGridEntry,
                extraParams : {multiselect : true},
                icon    : 'ui-icon-trash'
            },
        }
    });

    $("#services_list").on('gridChange', reloadServices);
}

function createUpdateNodeButton(container, elem_id, grid_id) {
    var import_button = $("<button>", { text : 'Import nodes', title : 'Add new nodes in service', 'class':'update_node_button' })
        .button({ icons : { primary : 'ui-icon-import' } });
    var synchro_button = $("<button>", { text : 'Synchronize', title : 'Add new nodes in service and remove old nodes', 'class':'update_node_button' })
        .button({ icons : { primary : 'ui-icon-arrowthick-2-e-w' } });

    // Check if there is a configured directory service
    var manager = isThereAManager(elem_id, 'DirectoryServiceManager');
    if (manager) {
        function bindButton(button, data) {
            button.bind('click', function(event) {
                require('common/general.js');
                callMethodWithPassword({
                        login        : manager.ad_user,
                        dialog_title : "Update service nodes",
                        url          : '/api/externalcluster/' + elem_id + '/updateNodes',
                        data         : data,
                        success      : function(data) {
                            $('#'+grid_id).trigger("reloadGrid");
                            if (data) {
                                alert(
                                        data.retrieved_node_count + ' nodes retrieved\n' +
                                        data.added_node_count     + ' nodes added to service\n' +
                                        data.removed_node_count   + ' nodes removed from service'
                                );
                            }
                        }
                });
            });
        }
        bindButton(import_button, {});
        bindButton(synchro_button, { synchro : 1 });
    } else {
        function disableButton(button) {
            button.attr('disabled', 'disabled');
            button.addClass("ui-state-disabled");
            button.attr('title', 'Your service must be connected with a directory.');
        }
        disableButton(import_button);
        disableButton(synchro_button);
    }
    // Finally, append the button in the DOM tree
    $(container).append(import_button);
    $(container).append(synchro_button);
}

function _buttonEnabling (grid, rowid, action_enable) {
    $('#' + rowid).find('.node_control .ui-button-text').html(action_enable ? 'Disable' : 'Enable').attr('title',action_enable ? 'Disable node' : 'Enable node');
    var td = $(grid).find('tr#' + rowid + ' td');
    action_enable ? td.removeClass('node-disabled') : td.addClass('node-disabled');
}

function loadServicesResources (container_id, elem_id) {
    var loadServicesResourcesGridId = 'service_resources_list_' + elem_id;
    var nodemetricrules;
    var action_buttons_container = $('#' + container_id).prevAll('.action_buttons');

    createUpdateNodeButton(action_buttons_container, elem_id, loadServicesResourcesGridId);

    // Manage enable/disable nodes and add control button in grid
    function manageNodeEnabling(grid, rowid, rowdata, rowelem) {
        var node_disabled = rowelem.monitoring_state === 'disabled';
        if (node_disabled) {
            $(grid).find('tr#' + rowid + ' td').addClass('node-disabled');
        }
        var cell = $(grid).find('tr#' + rowid).find('td[aria-describedby="' + loadServicesResourcesGridId + '_activate_control"]');
        var activateButton  = $('<div>', {'class' : 'node_control', html : node_disabled ? 'Enable' : 'Disable', css : 'position:center',title:node_disabled ? 'Enable node' : 'Disable node'}).button().appendTo(cell);
        $(activateButton).attr('style', 'margin-top:0px;');
        $(activateButton).click(function() {
            var action          = $(this).find('.ui-button-text').html().toLowerCase();
            var action_enable   = (action  === 'enable');
            $.ajax({
                type        : 'POST',
                url         : '/api/serviceprovider/' + elem_id + '/' + action + 'Node',
                contentType : 'application/json',
                data        : JSON.stringify( {
                    node_id : rowid
                }),
                success     : function() {
                    _buttonEnabling(grid, rowid, action_enable);
                }
            });
        });
    }

    $.ajax({
        url     : '/api/nodemetricrule?service_provider_id=' + elem_id,
        success : function(data) {
            nodemetricrules   = data;
        }
    });
    create_grid( {
        url     : '/nodes?service_provider_id=' + elem_id + '&expand=verified_noderules',
        content_container_id: container_id,
        grid_id     : loadServicesResourcesGridId,
        grid_class  : 'service_resources_list',
        rowNum      : 25,
        sortname    : 'monitoring_state',
        sortorder   : 'desc',
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            // Add generic resource data
            function addExtra() {
                if (!nodemetricrules) {
                    setTimeout(addExtra, 10);
                } else {
                    addResourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, elem_id, 'external');
                }
            }
            addExtra();
            // Manage enable/disable state and control
            manageNodeEnabling(grid, rowid, rowdata, rowelem);
        },
        beforeShowDetails: function(gridid, rowid) {
            var control = $('#'+gridid).find('tr#' + rowid).find('.node_control');
            var is_disable = control.find('.ui-button-text').html() === 'Enable';
            if (is_disable) {
                alert('This node is disabled');
                return false;
            }
            return true;
        },
        colNames: [ 'id', 'Hostname', 'Rules State', '' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'node_hostname', index: 'node_hostname', width: 200 },
            { name: 'rulesstate', index: 'rulestate' },
            { name: 'activate_control', index: 'monitoring_state', width: 50, nodetails : true }
        ],
        details : {
            tabs : [
                { label : 'Rules'     , id : 'rules'          , onLoad : function(cid, eid) { node_rules_tab(cid, eid, elem_id); } },
                { label : 'Monitoring', id : 'node_monitoring', onLoad : function(cid, eid) { node_monitoring_tab(cid, eid, elem_id); } },
            ],
            title   : { from_column : 'node_hostname' },
            height  : 600,
            buttons : ['button-ok']
        },
        action_delete: {url : '/api/node'},
        multiselect : true,
        multiactions : {
            nodeEnable : {
                label   : 'Enable node(s)',
                title   :'Enable node(s)',
                action  : gridGenericPost,
                url     : '/api/serviceprovider/' + elem_id + '/enableNode',
                icon    : 'ui-icon-ok',
                afterAction  : function(grid_id, rowid) {
                    _buttonEnabling('#' + grid_id, rowid, true);
                }
            },
            nodeDisable : {
                label   : 'Disable node(s)',
                title   : 'Disable node(s)',
                action  : gridGenericPost,
                url     : '/api/serviceprovider/' + elem_id + '/disableNode',
                icon    : 'ui-icon-cancel',
                afterAction  : function(grid_id, rowid) {
                    _buttonEnabling('#' + grid_id, rowid, false);
                }
            },
            multiDelete : {
                label   : 'Delete node(s)',
                title   : 'Delete node(s)',
                action  : removeGridEntry,
                icon    : 'ui-icon-trash',
                url     : '/api/node',
                extraParams : {multiselect : true}
            }
        }
    } );

    //reload_grid(loadServicesResourcesGridId,'/api/node?outside_id=' + elem_id);
    $('service_resources_list').jqGrid('setGridWidth', $(container_id).parent().width()-20);
}
