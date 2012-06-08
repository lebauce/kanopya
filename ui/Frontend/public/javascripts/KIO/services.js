// Some global service variables declaration
// TODO a nice class :)

// Current service instance
var service_id;

// Dashboard instance used to all services dashboard
var service_dashboard;

// DOM element used by dashboard
var dash_div;
var dash_header;
var dash_template;

$(document).ready(function() {
    // Create and init dashboard used for services
    initServiceDashboard();
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
    dash_header.append('<a class="openaddwidgetdialog headerlink" href="#"><font color="black">Add Widget</font></a>&nbsp;&nbsp;');
    dash_header.append('<a class="editlayout headerlink" href="#"><font color="black">Edit layout</font></a>&nbsp;&nbsp;');
    dash_header.append('<a class="savedashboard headerlink" href="#"><font color="black">Save Dashboard</font></a>');

    $('body').append(dash_header);
    $('body').append(dash_div);

    // Dashboard template
    var template_id = "template";
    dash_template =  $('<div id="template"></div>');
    $('body').append(dash_template);
    $("#template").hide();
    $("#template").load("dashboard_templates.html", initDashboard);

    function initDashboard() {

        // to make it possible to add widgets more than once, we create clientside unique id's
        // this is temporary and not working (i.e give the same id to a newly added widget that loaded widget from saved dash
        // TODO better id management
        var startId = 100;

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

            obj.widget.addMetadataValue("service_id", service_id);

            obj.widget.element.trigger('widgetLoadContent',{"widget":obj.widget});
        });

        service_dashboard = s_dashboard;
    } // end inner function initDasboard
}

// Set the correct state icon for each element :
function StateFormatter(cell, options, row) {
	if (cell == 'up') {
		return "<img src='/images/icons/up.png' title='up' />";
	} else {
		return "<img src='/images/icons/broken.png' title='broken' />";
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

function createSpecServDialog(provider_id, name, first, category, elem, editid) {
    var allFields   = {
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
        'mockmonitor'       : {}
    };
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
    for (option in options) {
        option = options[option];
        $(select).append($("<option>", { value : option.connector_name.toLowerCase(), text : option.connector_name }));
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
    // create the default form (activedirectory for directory and scom for monitoring)
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

    var button = $("<button>", {html : 'Add a service'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    });   
    $(container).append(button);
};

function servicesList (container_id, elem_id) {
    var container = $('#' + container_id);
    
    create_grid(container_id, 'services_list',
                ['ID','Name', 'State'],
                [ 
                 {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
                 {name:'externalcluster_name',index:'service_name', width:200},
                 {name:'externalcluster_state',index:'service_state', width:90,formatter:StateFormatter},
                 ]);
    reload_grid('services_list', '/api/externalcluster');
    
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

function loadServicesConfig (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';
    
    if (isThereAConnector(elem_id, 'DirectoryService') === false) {
        var b   = $("<a>", { text : 'Add a Directory Service', id : 'adddirectory' });
        b.bind('click', function() { createMonDirDialog(elem_id, 'DirectoryService').start(); });
        b.appendTo(container).button({ icons : { primary : 'ui-icon-plusthick' } });
    }
    
    if (isThereAConnector(elem_id, 'MonitoringService') === false) {
        var bu  = $("<button>", { text : 'Add a Monitoring Service', id : 'addmonitoring' });
        bu.bind('click', function() { createMonDirDialog(elem_id, 'MonitoringService').start(); });
        bu.appendTo(container).button({ icons : { primary : 'ui-icon-plusthick' } });
    }
    
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
            var table = $("<table>").appendTo(container);
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
                    that.createSpecServDialog(elem_id, name[0], false, name[1], undefined, id).start();
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
        }
    });
}

function loadServicesRessources (container_id, elem_id) {
	var loadServicesRessourcesGridId = 'service_ressources_list_' + elem_id;
	create_grid(container_id, loadServicesRessourcesGridId,
            ['id','state', 'hostname'],
            [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'externalnode_state',index:'externalnode_state', width:90,formatter:StateFormatter},
             {name:'externalnode_hostname',index:'externalnode_hostname', width:200,},
           ]);
    reload_grid('service_ressources_list', '/api/host');

    createUpdateNodeButton($('#' + container_id), elem_id);
    reload_grid(loadServicesRessourcesGridId,'/api/externalnode?outside_id=' + elem_id);
    $('service_ressources_list').jqGrid('setGridWidth', $(container_id).parent().width()-20);
   
}

function loadServicesMonitoring (container_id, elem_id) {

	var container = $("#" + container_id);
	
	$("<div>", { html : "Clustermetric : " }).appendTo(container);
	var loadServicesMonitoringGridId = 'service_ressources_clustermetrics_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'indicator'],
            [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'clustermetric_label',index:'clustermetric_label', width:90,},
             {name:'clustermetric_indicator_id',index:'clustermetric_indicator_id', width:200,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/clustermetrics');
    
    $("<div>", { html : "<br />Aggregate Combinations : " }).appendTo(container);
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_combinations_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'formula'],
            [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_combination_label',index:'aggregate_combination_label', width:90,},
             {name:'aggregate_combination_formula',index:'aggregate_combination_formula', width:200,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/aggregate_combinations');
	
	$("<div>", { html : "<br />Nodemetric Combinations : " }).appendTo(container);
	var loadServicesMonitoringGridId = 'service_ressources_nodemetric_combination_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'formula'],
            [ 
             {name:'pk',index:'pk', width:90, sorttype:"int", hidden:true, key:true},
             {name:'nodemetric_combination_label',index:'nodemetric_combination_label', width:120,},
             {name:'nodemetric_combination_formula',index:'nodemetric_combination_formula', width:170,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/nodemetric_combinations');
}

function loadServicesRules (container_id, elem_id) {
	
	var container = $("#" + container_id);
	
	$("<div>", { text : "Nodemetric Conditions : " }).appendTo(container);
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_condition_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'separator', 'threshold'],
            [ 
             {name:'pk',index:'pk',sorttype:"int", hidden:true, key:true},
             {name:'nodemetric_condition_label',index:'nodemetric_condition_label',width:120,},
             {name:'nodemetric_condition_comparator',index:'nodemetric_condition_comparator',width:220,},
             {name:'nodemetric_condition_threshold',index:'nodemetric_condition_threshold',width:220,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/nodemetric_conditions');
    
    //$('#' + loadServicesMonitoringGridId).jqGrid('setGridWidth', $('#' + loadServicesMonitoringGridId).width('700px'));
    
    $("<div>", { html : "<br />Nodemetric Rules : " }).appendTo(container);
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_rules_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'state', 'eval', 'description', 'timestamp', 'formula'],
            [ 
             {name:'pk',index:'pk', sorttype:"int", hidden:true, key:true},
             {name:'nodemetric_rule_label',index:'nodemetric_rule_label',width:120,},
             {name:'nodemetric_rule_state',index:'nodemetric_rule_state',width:60,formater:StateFormatter},
             {name:'nodemetric_rule_last_eval',index:'nodemetric_rule_last_eval',width:60},
             {name:'nodemetric_rule_description',index:'nodemetric_rule_description',width:190,},
             {name:'nodemetric_rule_timestamp',index:'nodemetric_rule_timestamp',width:60,},
             {name:'nodemetric_rule_formula',index:'nodemetric_rule_formula',width:60,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/nodemetric_rules');
    
    //$('#' + loadServicesMonitoringGridId).jqGrid('setGridWidth', $('#' + loadServicesMonitoringGridId).width('700px'));
    
    $("<div>", { html : "<br />Aggregate Conditions : " }).appendTo(container);
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_conditions_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'state', 'threshold', 'last eval', 'time limit'],
            [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_condition_label',index:'aggregate_condition_label', width:120,},
             {name:'state',index:'state', width:60,formatter:StateFormatter},
             {name:'threshold',index:'threshold', width:60,},
             {name:'last_eval',index:'last_eval', width:160,},
             {name:'time_limit',index:'time_limit', width:160,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/aggregate_conditions');
	
	$("<div>", { html : "<br />Aggregate Rules : " }).appendTo(container);
	var loadServicesMonitoringGridId = 'service_ressources_aggregate_rules_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'state', 'formula', 'description', 'timestamp'],
            [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_rule_label',index:'aggregate_rule_label', width:90,},
             {name:'aggregate_rule_state',index:'aggregate_rule_state', width:90,formatter:StateFormatter},
             {name:'aggregate_rule_formula',index:'aggregate_rule_formula', width:90,},
             {name:'aggregate_rule_description',index:'aggregate_rule_description', width:200,},
             {name:'aggregate_rule_timestamp',index:'aggregate_rule_timestamp', width:90,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/aggregate_rules');
}