require('common/grid.js');
require('common/workflows.js');
require('common/alerts.js');
require('common/formatters.js');

function loadServiceEventsAlerts(container_id, elem_id) {
    var container = $("#" + container_id);
    
    /* workflows part */
    
    var divWorkflows = $('<div id="accordionworkflows">').appendTo(container);
    $('<h3><a href="#">Workflows</a></h3>').appendTo(divWorkflows);
    $('<div id="workflows_accordion_container">').appendTo(divWorkflows);
    runningworkflowslist('workflows_accordion_container', elem_id);
    historicworkflowslist('workflows_accordion_container', elem_id);
    
    $('#accordionworkflows').accordion({
        autoHeight  : false,
        active      : false,
        collapsible : true,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    }).accordion('option', 'active', 0); // trigger change callback
    
    /* alerts part */
    
    var divAlerts = $('<div id="accordionalerts">').appendTo(container);
    $('<h3><a href="#">Alerts</a></h3>').appendTo(divAlerts);
    $('<div id="alerts_accordion_container">').appendTo(divAlerts);
    currentalertslist('alerts_accordion_container', elem_id);
    historicalertslist('alerts_accordion_container', elem_id);
    
    $('#accordionalerts').accordion({
        autoHeight  : false,
        active      : false,
        collapsible : true,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    }).accordion('option', 'active', 0); // trigger change callback
}
