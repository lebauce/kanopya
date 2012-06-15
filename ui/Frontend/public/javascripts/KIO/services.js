
// Some global service variables declaration
// TODO a nice class :)

require('modalform.js');

// Current service instance
var service_id;

// Dashboard instance used for all services dashboard
var service_dashboard;

// DOM element used by dashboard
var dash_div;
var dash_header;
var dash_template;

$(document).ready(function() {
    // Create and init dashboard used for services
    //initServiceDashboard();
});

function initServiceDashboard() {
    // Dashboard
    dash_div = $('<div id="service_dashboard" class="dashboard"></div>');
    var dash_layout_div = $('<div class="layout">');
    dash_layout_div.append('<div class="column first column-first"></div>');
    dash_layout_div.append('<div class="column second column-second"></div>');
    dash_layout_div.append('<div class="column third column-third"></div>');
    dash_div.append(dash_layout_div);

    // Dashboard actions
    dash_header = $('<div class="headerlinks"></div>');
    dash_header.append($('<button>', { 'class' : 'openaddwidgetdialog', html : 'Add Widget'}));
//    dash_header.append($('<button>', { 'class' : 'editlayout', html : 'Edit layout'}));
    dash_header.append($('<button>', { 'class' : 'savedashboard', html : 'Save Dashboard'}));


 
 
    //$('#view-container').append(dash_header);
    $('#view-container').append(dash_div);

    // Dashboard template
    var template_id = "template";
    dash_template =  $('<div id="template"></div>');
    $('body').append(dash_template);
    $("#template").hide();
    //$("#template").load("dashboard_templates.html", initDashboard);

    $.ajax({
        url: "dashboard_templates.html",
        async : false,
        success : function(data) {
            $('#template').html(data);
            initDashboard();
        }
      });

    function initDashboard() {

        // to make it possible to add widgets more than once, we create clientside unique id's
        // this id is update when loading existing widgets to always be the greater id
        var startId = 1;

        var s_dashboard = $('#service_dashboard').dashboard({

            debuglevel: 3,

            // override default settings
            loadingHtml: '<div class="loading"><img alt="Loading, please wait" src="/css/theme/loading.gif" /><p>Loading...</p></div>',

            // layout class is used to make it possible to switch layouts
            layoutClass:'layout',

            // feed for the widgets which are on the dashboard when opened
            json_data : {
                url: "jsonfeed/ondashboarddefault_widgets.json"
            },

            // json feed; the widgets whcih you can add to your dashboard
            addWidgetSettings: {
                widgetDirectoryUrl:"jsonfeed/widgetcategories.json",
                //dialogId: 'addwidgetdialog_' + elem_id
            },

            // Definition of the layout
            // When using the layoutClass, it is possible to change layout using only another class. In this case
            // you don't need the html property in the layout
            layouts :
                [
                 {title: "Layout1",
                     id: "layout1",
                     image: "layouts/layout1.png",
                     classname: 'layout-a'
                 },
                 { title: "Layout2",
                     id: "layout2",
                     image: "layouts/layout2.png",
                     classname: 'layout-aa'
                 },
                 { title: "Layout3",
                     id: "layout3",
                     image: "layouts/layout3.png",
                     classname: 'layout-ba'
                 },
                 { title: "Layout4",
                     id: "layout4",
                     image: "layouts/layout4.png",
                     classname: 'layout-ab'
                 },
                 { title: "Layout5",
                     id: "layout5",
                     image: "layouts/layout5.png",
                     classname: 'layout-aaa'
                 }
                 ]
        }); // end dashboard call

        // binding for a widgets is added to the dashboard
        s_dashboard.element.live('dashboardAddWidget',function(e, obj){
            var widget = obj.widget;

            s_dashboard.addWidget({
                "id":startId++,
                "title":widget.title,
                "url":widget.url,
                "column":widget.column || 'first',
                "metadata":widget.metadata
                },
                s_dashboard.element.find('.column:first')
            );
        });

        // binding for layout change
        s_dashboard.element.live('dashboardLayoutChanged',function(e){
            for (var widx in s_dashboard.widgets) {
                s_dashboard.widgets[widx].refreshContent();
            }
        });

        // binding for widget loaded
        s_dashboard.element.live('widgetLoaded',function(e, obj){

            var widgetEl = obj.widget.element;

            // Update the next id for future added widget
            var widget_id = parseInt(obj.widget.id);
            if (startId <= widget_id) {
                startId = widget_id + 1;
            }

            obj.widget.addMetadataValue("service_id", service_id);

            obj.widget.element.trigger('widgetLoadContent',{"widget":obj.widget});
        });

        service_dashboard = s_dashboard;
    } // end inner function initDasboard
}
var comparators = ['<','>'];
var rulestates = ['enabled','disabled'];
var statistics_function_name = ['mean','variance','std','max','min','kurtosis','skewness','dataOut','sum'];

// Set the correct state icon for each element :
function StateFormatter(cell, options, row) {
	//if (cell == 'up') {
	if ( cell.indexOf('up') != -1 ) {
		return "<img src='/images/icons/up.png' title='up' />";
	} else if ( cell.indexOf('broken') != -1 ) {
		return "<img src='/images/icons/broken.png' title='broken' />";
	} else {
	    return "<img src='/images/icons/down.png' title='down' />";
	}
}

function serviceStateFormatter(cell, options, row) {
	if (cell == 'enabled') {
		return "<img src='/images/icons/up.png' title='enabled' />";
	} else {
		return "<img src='/images/icons/down.png' title='disabled' />";
	}
}
 
// Check if there is a configured directory service
function isThereAConnector(elem_id, connector_category) {
    var is  = false;
    
    // Get all configured connectors on the service
    $.ajax({
        async   : false,
        url     : '/api/connector?service_provider_id=' + elem_id,
        success : function(connectors) {
            for (i in connectors) if (connectors.hasOwnProperty(i)) {
                // Get the connector type for each
                $.ajax({
                    async   : false,
                    url     : '/api/connectortype?connector_type_id=' + connectors[i].connector_type_id,
                    success : function(data) {
                        // If this is a Directory Service, then we can return true
                        if (data[0].connector_category === connector_category) {
                            is  = true;
                        }
                    }
                });
                if (is) {
                    break;
                }
            }
        }
    });
    
    return is;
}

function getAllConnectorFields() {
    return {
        'activedirectory'   : {
            ad_host             : {
                label   : 'Domain controller',
                help    : 'May be the Domain Controller name or the Domain Name'
            },
            ad_nodes_base_dn    : {
                label   : 'Nodes container DN',
                help    : 'The Distinguished Name of either:<br/> - OU<br/>- Group<br/>- Container'
            },
            ad_user             : {
                label   : 'User@domain'
            },
            ad_usessl           : {
                label   : 'Use SSL ?',
                type    : 'checkbox'
            }
        },
        'scom'              : {
            scom_ms_name        : {
                label   : 'Root Management Server FQDN'
            },
            scom_usessl         : {
                label   : 'Use SSL ?',
                type    : 'checkbox'
            },
        },
        'sco'               : {},
        'mockmonitor'       : {}
    };
}

function createSpecServDialog(provider_id, name, first, category, elem, editid) {
    var allFields   = getAllConnectorFields();
    var ad_opts     = {
        title           : ((editid === undefined) ? 'Add' : 'Edit') + ' a ' + category,
        name            : name,
        fields          : allFields[name],
        prependElement  : elem,
        id              : editid
    };
    ad_opts.fields.service_provider_id = {
        label   : '',
        type    : 'hidden',
        value   : provider_id
    };
    if (first) {
        ad_opts.skippable   = true;
        var step            = 3;
        if (category === 'DirectoryService') {
            ad_opts.callback    = function() {
                createMonDirDialog(provider_id, 'MonitoringService', first).start();
            };
            step    = 2;
        }
        ad_opts.title       = 'Step ' + step + ' of 3 : ' + ad_opts.title;
    } else {
        ad_opts.callback    = function() {
            var container = $('div#content_service_configuration_' + provider_id);
            container.empty();
            loadServicesConfig(container.attr('id'), provider_id);
        };
    }
    return new ModalForm(ad_opts);
}

function createMonDirDialog(elem_id, category, firstDialog) {
    var ADMod;
    select          = $("<select>");
    var options;
    $.ajax({
        async   : false,
        type    : 'get',
        url     : '/api/connectortype?connector_category=' + category,
        success : function(data) {
            options = data;
        }
    });
    var fields      = getAllConnectorFields();
    for (option in options) {
        option = options[option];
        if (fields.hasOwnProperty(option.connector_name.toLowerCase())) {
            $(select).append($("<option>", { value : option.connector_name.toLowerCase(), text : option.connector_name }));
        }
    }
    $(select).bind('change', function(event) {
        var name    = event.currentTarget.value;
        var newMod  = createSpecServDialog(elem_id, name, firstDialog, category);
        $(ADMod.form).remove();
        ADMod.form  = newMod.form;
        ADMod.handleArgs(newMod.exportArgs());
        $(ADMod.content).append(ADMod.form);
        ADMod.startWizard();
    });
    ADMod   = createSpecServDialog(elem_id, $(select).attr('value'), firstDialog, category, select);
    return ADMod;
}

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
        title       : 'Step 1 of 3 : Add a Service',
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
            return true;
        },
        callback    : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
            reloadServices();
            createMonDirDialog(data.pk, 'DirectoryService', true).start();
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
    ////////////////////////MONITORING MODALS//////////////////////////////////
function createServiceMetric(container_id, elem_id) {
    var service_fields  = {
        clustermetric_label    : {
            label   : 'Name',
            type	: 'text',
        },
        clustermetric_statistics_function_name    : {
            label   : 'Statistic function name',
            type    : 'select',
            options   : statistics_function_name,
        },
        clustermetric_window_time	: {
        	label	: 'Window time',
        	type	: 'text',	
        },
        clustermetric_indicator_id	:{
        	label	: 'Combination',
        	display	: 'clustermetric_indicator_label',
        },
        clustermetric_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,	
        }
    };
    var service_opts    = {
        title       : 'Create a Service Metric',
        name        : 'clustermetric',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a nodemetric condition'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceConbination(container_id, elem_id) {
    var service_fields  = {
        aggregate_combination_label    : {
            label   : 'Name',
            type	: 'text',
        },
        aggregate_combination_formula    : {
            label   : 'Formula',
            type	: 'text',
        },
        aggregate_combination_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,	
        },
    };
    var service_opts    = {
        title       : 'Create a Service Combination',
        name        : 'aggregatecombination',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a service combination'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createNodemetricCombination(container_id, elem_id) {
    var service_fields  = {
        nodemetric_combination_label    : {
            label   : 'Name',
            type	: 'text',
        },
        nodemetric_combination_formula    : {
            label   : 'Formula',
            type	: 'text',
        },
        aggregate_combination_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,	
        },
    };
    var service_opts    = {
        title       : 'Create a Nodemetric Combination',
        name        : 'nodemetriccombination',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a nodemetric combination'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

    ////////////////////////NODES AND METRICS MODALS//////////////////////////////////
function createNodemetricCondition(container_id, elem_id) {
    var service_fields  = {
        nodemetric_condition_label    : {
            label   : 'Name',
            type	: 'text',
        },
        nodemetric_condition_combination_id	:{
        	label	: 'Combination',
        	display	: 'nodemetric_combination_label',
        },
        nodemetric_condition_comparator    : {
            label   : 'Comparator',
            type    : 'select',
            options   : comparators,
        },
        nodemetric_condition_threshold	: {
        	label	: 'Threshold',
        	type	: 'text',	
        },
        nodemetric_condition_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,	
        }
    };
    var service_opts    = {
        title       : 'Create a Nodemetric Condition',
        name        : 'nodemetriccondition',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a nodemetric condition'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createNodemetricRule(container_id, elem_id) {
    var service_fields  = {
        nodemetric_rule_label    : {
            label   : 'Name',
            type	: 'text',
        },
        nodemetric_rule_description    : {
            label   : 'Description',
            type    : 'textarea',
        },
        nodemetric_rule_formula	: {
        	label	: 'Formula',
        	type	: 'text',	
        },
        nodemetric_rule_state	:{
        	label   : 'Enabled',
	        type    : 'select',
    	    options   : rulestates,
        },
        nodemetric_rule_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,
        },
    };
    var service_opts    = {
        title       : 'Create a Nodemetric Rule',
        name        : 'nodemetricrule',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a nodemetric rule'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceCondition(container_id, elem_id) {
    var service_fields  = {
        aggregate_condition_label    : {
            label   : 'Name',
            type	: 'text',
        },
        aggregate_combination_id	:{
        	label	: 'Combination',
        	display	: 'aggregate_combination_label',
        },
        comparator	: {
        	label   : 'Comparator',
	        type    : 'select',
    	    options   : comparators,	
        },
        threshold	:{
        	label	: 'Threshold',
        	type	: 'text',	
        },
        state	:{
        	label   : 'Enabled',
	        type    : 'select',
    	    options   : rulestates,
        },
        aggregate_condition_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,
        },
    };
    var service_opts    = {
        title       : 'Create a Service Condition',
        name        : 'aggregatecondition',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a Service Condition'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceRule(container_id, elem_id) {
	
	$('<div id="service_condition_listing_for_service_rule_creation">', { html : "pouet : " }).appendTo('#aggregaterule');
	
	var loadServicesMonitoringGridId = 'service_rule_creation_condition_listing_' + elem_id;
    create_grid( {
        url: '/api/nodemetriccondition',
        content_container_id: 'service_condition_listing_for_service_rule_creation',
        grid_id: loadServicesMonitoringGridId,
        /*afterInsertRow: function(grid, rowid) {
            var current = $(grid).getCell(rowid, 'clustermetric_indicator_id');
            var url     = '/api/externalcluster/' + elem_id + '/getIndicatorNameFromId';
            setCellWithCallMethod(url, grid, rowid, 'clustermetric_indicator_id', { 'indicator_id' : current });
        },*/
        colNames: [ 'id', 'name' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 90 },
        ]
    } );

    var service_fields  = {
        aggregate_rule_label    : {
            label   : 'Name',
            type	: 'text',
        },
        aggregate_rule_description	:{
        	label	: 'Description',
        	type	: 'textearea',	
        },
        aggregate_rule_formula	: {
        	label   : 'Formula',
            type	: 'text',	
        },
        clustermetric_label :{
            label   : 'Formula',
            display : 'clustermetric_label',   
        },
        aggregate_rule_state	:{
        	label   : 'Enabled',
	        type    : 'select',
    	    options   : rulestates,	
        },
        aggregate_rule_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,
        },
    };
    var service_opts    = {
        title       : 'Create a Service Rule',
        name        : 'aggregaterule',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a Service Rule'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};
    ////////////////////////END OF : NODES AND METRICS MODALS//////////////////////////////////

function servicesList (container_id, elem_id) {
    var container = $('#' + container_id);
    
    create_grid( {
        url: '/api/externalcluster',
        content_container_id: container_id,
        grid_id: 'services_list',
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            $.ajax({
                url     : '/api/externalcluster/' + id + '/externalnodes',
                type    : 'GET',
                success : function(data) {
                    var i   = 0;
                    $(data).each(function() {
                        ++i;
                    });
                    $(grid).setCell(rowid, 'node_number', i);
                }
            });
        },
        colNames: [ 'ID', 'Name', 'Enabled', 'Node Number' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'externalcluster_name', index: 'service_name', width: 200 },
            { name: 'externalcluster_state', index: 'service_state', width: 90, formatter:StateFormatter },
            { name: 'node_number', index: 'node_number', width: 150 }
        ],
        elem_name : 'service',
    });
    
    $("#services_list").on('gridChange', reloadServices);
    
    createAddServiceButton(container);
}

function createUpdateNodeButton(container, elem_id) {
    var button = $("<button>", { text : 'Update Nodes' }).button({ icons : { primary : 'ui-icon-refresh' } });
    // Check if there is a configured directory service
    if (isThereAConnector(elem_id, 'DirectoryService') === true) {
        $(button).bind('click', function(event) {
            var dialog = $("<div>", { css : { 'text-align' : 'center' } });
            dialog.append($("<label>", { for : 'adpassword', text : 'Please enter your password :' }));
            dialog.append($("<input>", { id : 'adpassword', name : 'adpassword' }));
            // Create the modal dialog
            $(dialog).dialog({
                modal           : true,
                title           : "Update service nodes",
                resizable       : false,
                draggable       : false,
                closeOnEscape   : false,
                buttons         : {
                    'Ok'    : function() {
                        var passwd  = $("input#adpassword").attr('value');
                        var ok      = false;
                        // If a password was typen, then we can submit the form
                        if (passwd !== "" && passwd !== undefined) {
                            $.ajax({
                                url     : '/kio/services/' + elem_id + '/nodes/update',
                                type    : 'post',
                                async   : false,
                                data    : {
                                    password    : passwd
                                },
                                success : function(data) {
                                    ok  = true;
                                }
                            });
                            // If the form succeed, then we can close the dialog
                            if (ok === true) {
                                $(this).dialog('destroy');
                            }
                        } else {
                            $("input#adpassword").css('border', '1px solid #f00');
                        }
                    },
                    'Cancel': function() {
                        $(this).dialog('destroy');
                    }
                }
            });
            $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
        });
    } else {
        $(button).attr('disabled', 'disabled');
        $(button).attr('title', 'Your service must be connected with a directory.')
    }
    // Finally, append the button in the DOM tree
    $(container).append(button);
}

function loadServicesOverview (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';

    // First init
    if (service_dashboard === undefined) {
        initServiceDashboard();
    }

    service_id = elem_id;

    $.ajax({
 		url: '/api/externalcluster?dataType=jqGrid',
 		success: function(data) {
			$(data.rows).each(function(row) {
				if ( data.rows[row].pk == elem_id ) {
    				externalclustername = data.rows[row].externalcluster_name;
    				$('<div>Overview for Service ' + externalclustername + '<div>').appendTo(container);
    			}
    		});
    	}
	});

    dash_div.hide();
    container.append(dash_header);
    container.append(dash_div);
    container.append(dash_template);

    // Make jquery button (must be done after append to container, each time)
    container.find(".openaddwidgetdialog").button({ icons : { primary : 'ui-icon-plusthick' } });
    container.find(".savedashboard").button({ icons : { primary : 'ui-icon-disk' } });

    //service_dashboard.setLayout(undefined);
    //service_dashboard.setLayout('layout2');

    // Set save dashboard callback
    $('.savedashboard').click(function () {
        $.getJSON('/api/dashboard?dashboard_service_provider_id=' + elem_id, function (resp) {
            // Default ajax req params (create dashboard conf)
            var req = {
                    url     : '/api/dashboard',
                    type    : 'POST',
                    data    : {
                                dashboard_config : service_dashboard.serialize(),
                                dashboard_service_provider_id : elem_id
                    },
                    success : function () {alert('Dashboard saved')},
                    error   : function () {alert('An error occured')} // TODO error management
            }
            // Change req params for update id dashboard conf exists
            if (resp.length > 0) {
                req.type    = 'PUT';
                req.url = req.url + '/' + resp[0].pk;
            }

            // Update or Create
            $.ajax(req);
        });
    });

    // Clear dashboard (remove widgets)
    $.each(service_dashboard.widgets, function(id, widget) {
        widget.remove();
        delete service_dashboard.widgets[id];
    });

    // Retrieve saved conf and set dashboard
    var dashboard_data;
    $.getJSON('/api/dashboard?dashboard_service_provider_id=' + elem_id, function (resp) {
        // Default dashboard conf (TODO load default from server)
        var conf = {
                url : 'jsonfeed/ondashboarddefault_widgets.json'
        };
        // Load saved dashboard conf if exist
        if (resp[0]) {
            conf = JSON.parse(resp[0].dashboard_config);
        }
        // Init dashboard
        service_dashboard.init({
            json_data : conf
        });
        dash_div.show();
    });

}

function scoConfigurationDialog(elem_id, sco_id) {
  console.log(sco_id);
}

function loadServicesConfig (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';
    
    var connectorsTypeHash = {};
    var connectorsTypeArray = new Array;
    
    var that = this;

    $.ajax({
        url     : '/api/externalcluster/' + elem_id,
        type    : 'GET',
        success : function(data) {
            var table   = $("<table>").css("width", "100%").appendTo(container);
            $(table).append($("<tr>").append($("<td>", { colspan : 2, class : 'table-title', text : "General" })));
            $(table).append($("<tr>").append($("<td>", { text : 'Name :', width : '100' })).append($("<td>", { text : data.externalcluster_name })));
            $(table).append($("<tr>").append($("<td>", { text : 'Description :' })).append($("<td>", { text : data.externalcluster_desc })));
            $(table).append($("<tr>", { height : '15' }).append($("<td>", { colspan : 2 })));
        }
    });

    $.ajax({
        url: '/api/connectortype?dataType=jqGrid',
        async   : false,
        success: function(connTypeData) {
                    $(connTypeData.rows).each(function(row) {
                    //connectorsTypeHash = { 'pk' : connTypeData.rows[row].pk, 'connectorName' : connTypeData.rows[row].connector_name };
                    var pk = connTypeData.rows[row].pk;
                    connectorsTypeArray[pk] = {
                        name        : connTypeData.rows[row].connector_name,
                        category    : connTypeData.rows[row].connector_category
                    };
                });
            }
    });

    $.ajax({
        url: '/api/connector?dataType=jqGrid&service_provider_id=' + elem_id,
        success: function(data) {
            var ctnr    = $("<div>", { id : 'connectorslistcontainer' });
            $(ctnr).appendTo(container);
            $(container).append($('<br />'));
            var table = $("<table>", { id : "connectorslist" }).prependTo(ctnr);
            $(table).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Connectors" })));
            $(data.rows).each(function(row) {
                var connectorTypePk = data.rows[row].connector_type_id;
                var connectorName = connectorsTypeArray[connectorTypePk].name || 'UnknownConnector';
                var tr  = $("<tr>", {
                    rel : connectorName.toLowerCase() + "|" + connectorsTypeArray[connectorTypePk].category.toLowerCase()
                }).append($("<td>", {
                    text : connectorsTypeArray[connectorTypePk].category + " :"
                }).css('padding-top', '6px')).append($("<td>", { text : connectorName }).css('padding-top', '6px'));
                var confButton  = $("<a>", { text : 'Configure', rel : data.rows[row].pk });
                var delButton   = $("<a>", { text : 'Delete', rel : data.rows[row].pk });
                $(tr).append($("<td>").append($(confButton))).append($("<td>").append($(delButton)));
                $(tr).appendTo(table);

                // Bind configure and delete actions on buttons
                $(confButton).bind('click', { button : confButton }, function(event) {
                    var button  = $(event.data.button);
                    var id      = $(button).attr('rel');
                    var name    = $(button).parents('tr').attr('rel').split('|');
                    if (name[0] === 'sco') {
                        that.scoConfigurationDialog(elem_id, id);
                    } else {
                        that.createSpecServDialog(elem_id, name[0], false, name[1], undefined, id).start();
                    }
                }).button({ icons : { primary : 'ui-icon-wrench' } });
                $(delButton).bind('click', { button : delButton }, function(event) {
                    var button  = $(event.data.button);
                    $.ajax({
                        type    : 'delete',
                        url     : '/api/' + button.parents('tr').attr('rel').split('|')[0] + '/' + button.attr('rel'),
                        success : function() {
                            $(container).empty();
                            that.loadServicesConfig(container_id, elem_id);
                        }
                    });
                }).button({ icons : { primary : 'ui-icon-trash' } });
            });

            if (isThereAConnector(elem_id, 'DirectoryService') === false) {
                var b   = $("<a>", { text : 'Add a Directory Service', id : 'adddirectory' });
                b.bind('click', function() { createMonDirDialog(elem_id, 'DirectoryService').start(); });
                b.appendTo($(ctnr)).button({ icons : { primary : 'ui-icon-plusthick' } });
            }
            
            if (isThereAConnector(elem_id, 'MonitoringService') === false) {
                var b  = $("<a>", { text : 'Add a Monitoring Service', id : 'addmonitoring' });
                b.bind('click', function() { createMonDirDialog(elem_id, 'MonitoringService').start(); });
                $(ctnr).append($("<br />"));
                b.appendTo($(ctnr)).button({ icons : { primary : 'ui-icon-plusthick' } });
            }
        
            if (isThereAConnector(elem_id, 'WorkflowManager') === false) {
                var b   = $("<a>", { text : 'Add a Workflow Connector', id : 'addworkflowmanager' });
                b.bind('click', function() { createMonDirDialog(elem_id, 'WorkflowManager').start(); });
                $(ctnr).append($("<br />"));
                b.appendTo($(ctnr)).button({ icons : { primary : 'ui-icon-plusthick' } });
            }
        }
    });

    $.ajax({
        url     : '/api/serviceprovidermanager?service_provider_id=' + elem_id,
        success : function(data) {
            var ctnr    = $("<div>", { id : "managerslistcontainer" });
            $(ctnr).appendTo($(container));
            var table   = $("<table>", { id : 'managerslist' }).prependTo($(ctnr));
            $(table).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Managers" })));

            for (var i in data) if (data.hasOwnProperty(i)) {
                $(table).append($("<tr>", { text : data[i].manager_type }));
            }

            var addManagerButton    = $("<a>", { text : 'Add a Manager' }).button({ icons : { primary : 'ui-icon-plusthick' } });
            addManagerButton.bind('click', function() {
                $.ajax({
                    url         : '/api/serviceprovider/' + elem_id + '/findManager',
                    type        : 'POST',
                    contentType : 'application/json',
                    data        : JSON.stringify({ 'category' : 'WorkflowManager' }),
                    success     : function(data) {
                        var select  = $("<select>", { name : 'managerselection' })
                        for (var i in data) if (data.hasOwnProperty(i)) {
                            var theName     = data[i].name;
                            var manager     = data[i];
                            $.ajax({
                                url     : '/api/externalcluster/' + data[i].service_provider_id,
                                async   : false,
                                success : function(data) {
                                    theName = data.externalcluster_name + " - " + theName;
                                    $(select).append($("<option>", { text : theName, value : manager.id }));
                                }
                            });
                        }
                        $("<fieldset>").append($(select)).appendTo(container).dialog({
                            title           : 'Add a manager',
                            closeOnEscape   : false,
                            draggable       : false,
                            resizable       : false,
                            buttons         : {
                                'Cancel'    : function() { $(this).dialog("destroy"); },
                                'Ok'        : function() {
                                    var dial    = this;
                                    $.ajax({
                                        url         : '/api/serviceprovidermanager',
                                        type        : 'POST',
                                        data        : {
                                            manager_type        : 'WorkflowManager',
                                            manager_id          : $(select).attr('value'),
                                            service_provider_id : elem_id,
                                        },
                                        success     : function() {
                                            $(dial).dialog("destroy");
                                            $(container).empty();
                                            that.loadServicesConfig(container_id, elem_id);
                                        }
                                    });
                                }
                            }
                        });
                    }
                });
            });
            addManagerButton.appendTo($(ctnr));
        }
    });

}

function loadServicesRessources (container_id, elem_id) {
    var loadServicesRessourcesGridId = 'service_ressources_list_' + elem_id;
    create_grid( {
        url: '/api/externalnode?outside_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesRessourcesGridId,
        grid_class: 'service_ressources_list',
        colNames: [ 'id', 'enabled', 'hostname' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'externalnode_state', index: 'externalnode_state', width: 90, formatter: StateFormatter },
            { name: 'externalnode_hostname', index: 'externalnode_hostname', width: 200 },
        ]
    } );

    createUpdateNodeButton($('#' + container_id), elem_id);
    //reload_grid(loadServicesRessourcesGridId,'/api/externalnode?outside_id=' + elem_id);
    $('service_ressources_list').jqGrid('setGridWidth', $(container_id).parent().width()-20);
}

function setCellWithCallMethod(url, grid, rowid, colName, data) {
    $.ajax({
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify(data || {}),
        url         : url,
        complete    : function(jqXHR, status) {
            if (status === 'success') {
                $(grid).setCell(rowid, colName, jqXHR.responseText);
            }
        }
    });
}

function loadServicesMonitoring (container_id, elem_id) {
	
	var container = $("#" + container_id);
    ////////////////////////MONITORING ACCORDION//////////////////////////////////
        	
    var divacc = $('<div id="accordion_monitoring_rule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);
    $('<div id="node_monitoring_accordion_container">').appendTo(divacc);
    var container = $("#" + container_id);
    
    $("<p>", { html : "Nodemetric Combinations  : " }).appendTo('#service_monitoring_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_combination_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/nodemetric_combinations',
        content_container_id: 'node_monitoring_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/nodemetriccombination/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'nodemetric_combination_formula');
        },
        colNames: [ 'id', 'name', 'formula' ],
        colModel: [ 
            { name: 'pk', index: 'pk', width: 90, sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_combination_label', index: 'nodemetric_combination_label', width: 120 },
            { name: 'nodemetric_combination_formula', index: 'nodemetric_combination_formula', width: 170 },
        ]
    } );
    createNodemetricCombination('node_monitoring_accordion_container', elem_id);


	$('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_monitoring_accordion_container">').appendTo(divacc);
   
    $("<p>", { html : "Service Metric  : " }).appendTo('#service_monitoring_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_clustermetrics_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/clustermetrics',
        content_container_id: 'service_monitoring_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid) {
            var current = $(grid).getCell(rowid, 'clustermetric_indicator_id');
            var url     = '/api/externalcluster/' + elem_id + '/getIndicatorNameFromId';
            setCellWithCallMethod(url, grid, rowid, 'clustermetric_indicator_id', { 'indicator_id' : current });
        },
        colNames: [ 'id', 'name', 'indicator' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
            { name: 'clustermetric_label', index: 'clustermetric_label', width: 90 },
            { name: 'clustermetric_indicator_id', index: 'clustermetric_indicator_id', width: 200 },
        ]
    } );
    createServiceMetric('service_monitoring_accordion_container', elem_id);
    
    $("<p>", { html : "Service Combinations  : " }).appendTo('#service_monitoring_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_combinations_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/aggregate_combinations',
        content_container_id: 'service_monitoring_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/aggregatecombination/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'aggregate_combination_formula');
        },
        colNames: [ 'id', 'name', 'formula' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'aggregate_combination_label', index: 'aggregate_combination_label', width: 90 },
            { name: 'aggregate_combination_formula', index: 'aggregate_combination_formula', width: 200 },
        ]
    } );
    createServiceConbination('service_monitoring_accordion_container', elem_id);
    
    $('#accordion_monitoring_rule').accordion({
        autoHeight  : false,
        active      : false,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    });
}

function loadServicesRules (container_id, elem_id) {
    var container = $("#" + container_id);
    
    ////////////////////////RULES ACCORDION//////////////////////////////////
        	
    var divacc = $('<div id="accordionrule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);
    $('<div id="node_accordion_container">').appendTo(divacc);
    // Display nodemetric conditions
    $("<p>", { html : "Node Conditions : " }).appendTo('#node_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_conditions_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/nodemetric_conditions',
        content_container_id: 'node_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        colNames: [ 'id', 'name', 'comparator', 'threshold' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 120 },
            { name: 'nodemetric_condition_comparator', index: 'nodemetric_condition_comparator', width: 60,},
            { name: 'nodemetric_condition_threshold', index: 'nodemetric_condition_threshold', width: 190 },
        ]
    } );
    createNodemetricCondition('node_accordion_container', elem_id)
    
    // Display nodemetric rules
    $("<p>", { html : "Node Rules : " }).appendTo('#node_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_rules_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/nodemetric_rules',
        content_container_id: 'node_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        grid_class: 'service_ressources_nodemetric_rules',
        colNames: [ 'id', 'name', 'enabled', 'description', 'formula' ],
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/nodemetricrule/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'nodemetric_rule_formula');
        },
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_rule_label', index: 'nodemetric_rule_label', width: 120 },
            { name: 'nodemetric_rule_state', index: 'nodemetric_rule_state', width: 60, formatter:serviceStateFormatter },
            { name: 'nodemetric_rule_description', index: 'nodemetric_rule_description', width: 190 },
            { name: 'nodemetric_rule_formula', index: 'nodemetric_rule_formula', width: 60 },
        ]
    } );
    createNodemetricRule('node_accordion_container', elem_id);
	// Here's the second part of the accordion :
    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_accordion_container">').appendTo(divacc);
    // Display service conditions :
    $("<p>", { html : "Service Conditions : " }).appendTo('#service_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_conditions_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/aggregate_conditions',
        content_container_id: 'service_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        colNames: ['id','name', 'enabled', 'threshold', 'comparator', 'time limit'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_condition_label',index:'aggregate_condition_label', width:120,},
             {name:'state',index:'state', width:60,formatter:serviceStateFormatter},
             {name:'threshold',index:'threshold', width:60,},
             {name:'comparator',index:'comparator', width:160,},
             {name:'threshold',index:'threshold', width:160,},
           ]
    } );
    createServiceCondition('service_accordion_container', elem_id);
    // Display services rules :
    $("<p>", { html : "Service Rules : " }).appendTo('#service_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_rules_' + elem_id;
    create_grid( {
        url: '/api/externalcluster/' + elem_id + '/aggregate_rules',
        content_container_id: 'service_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        colNames: ['id','name', 'enabled', 'formula', 'description'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_rule_label',index:'aggregate_rule_label', width:90,},
             {name:'aggregate_rule_state',index:'aggregate_rule_state', width:90,formatter:serviceStateFormatter},
             {name:'aggregate_rule_formula',index:'aggregate_rule_formula', width:90,},
             {name:'aggregate_rule_description',index:'aggregate_rule_description', width:200,},
           ],
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/aggregaterule/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'aggregate_rule_formula');
        },
    } );
    createServiceRule('service_accordion_container', elem_id);

    $('#accordionrule').accordion({
        autoHeight  : false,
        active      : false,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    });
    
    ////////////////////////END OF : RULES ACCORDION//////////////////////////////////
}