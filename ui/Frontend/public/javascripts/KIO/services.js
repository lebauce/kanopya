
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

function lastevalStateFormatter(cell, options, row) {
	//if (cell == 'up') {
	if ( cell == 0 ) {
		return "<img src='/images/icons/up.png' title='up' />";
	} else if ( cell == 1 ) {
		return "<img src='/images/icons/broken.png' title='broken' />";
	} else if ( cell == null ) {
	    return "<img src='/images/icons/down.png' title='down' />";
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

function isThereAManager(elem_id, category) {
    var is  = false;

    $.ajax({
        url         : '/api/serviceprovider/' + elem_id + '/getManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'manager_type' : category }),
        async       : false,
        success     : function(data) {
            is  = true;
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
        title           : ((editid === undefined) ? 'Add a ' + category : 'Edit ' + name),
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
    
    
    var indicators = {};
    $.ajax({
        async   : false,
 		url: '/api/scomindicator?service_provider_id=' + elem_id,
 		success: function(rows) {
		   $(rows).each(function(row) {
    	       indicators[rows[row].scom_indicator_name] = rows[row].scom_indicator_id;
    	   });
  		}
	});
    
    var service_fields  = {
        clustermetric_label    : {
            label   : 'Name',
            type	: 'text',
        },
        clustermetric_indicator_id	:{
        	label	: 'Indicator',
        	type	: 'select',
        	options : indicators,
        },
        clustermetric_statistics_function_name    : {
            label   : 'Statistic function name',
            type    : 'select',
            options   : statistics_function_name,
        },
        clustermetric_window_time   :{
            type    : 'hidden',
            value   : '1200',
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

    var button = $("<button>", {html : 'Add a service metric'});
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
        title       : 'Create a Combination',
        name        : 'aggregatecombination',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a combination'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
                    ////////////////////////////////////// Service Combination Forumla Construction ///////////////////////////////////////////
        
        $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/aggregatecombination?dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].aggregate_combination_label, value : answer.rows[row].aggregate_combination_id});

                });
            }
    });

    function split( val ) {
			return val.split( / \s*/ );
		}
	    function extractLast( term ) {
			return split( term ).pop();
		}

		$( "#input_aggregate_combination_formula" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				minLength: 0,
				source: function( request, response ) {
					// delegate back to autocomplete, but extract the last term
					response( $.ui.autocomplete.filter(
						availableTags, extractLast( request.term ) ) );
				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					terms.push( "id" + ui.item.value );
					// add placeholder to get the comma-and-space at the end
					//terms.push( "" );
					this.value = terms;
					this.value = terms.join(" ");
					return false;
				}
			});
	});
    ////////////////////////////////////// END OF : Service Combination Forumla Construction ///////////////////////////////////////////

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
            label   : 'Indicators Formula',
            type	: 'text',
        },
        nodemetric_combination_service_provider_id	:{
        	type	: 'hidden',
        	value	: elem_id,	
        },
    };
    var service_opts    = {
        title       : 'Create a Combination',
        name        : 'nodemetriccombination',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a combination'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
            ////////////////////////////////////// Node Combination Forumla Construction ///////////////////////////////////////////
        
        $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/scomindicator?service_provider_id=' + elem_id + '&dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].scom_indicator_name, value : answer.rows[row].scom_indicator_id});
                });
            }
    });

    function split( val ) {
			return val.split( / \s*/ );
		}
	    function extractLast( term ) {
			return split( term ).pop();
		}

		$( "#input_nodemetric_combination_formula" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				minLength: 0,
				source: function( request, response ) {
					// delegate back to autocomplete, but extract the last term
					response( $.ui.autocomplete.filter(
						availableTags, extractLast( request.term ) ) );
				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					terms.push( "id" + ui.item.value );
					// add placeholder to get the comma-and-space at the end
					//terms.push( "" );
					this.value = terms;
					this.value = terms.join(" ");
					return false;
				}
			});
	});
    ////////////////////////////////////// END OF : Node Combination Forumla Construciton ///////////////////////////////////////////

    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

    ////////////////////////NODES AND METRICS MODALS//////////////////////////////////
function nodemetricconditionmodal(elem_id, editid) {
    var service_fields  = {
        nodemetric_condition_label    : {
            label   : 'Name',
            type    : 'text',
        },
        nodemetric_condition_combination_id :{
            label   : 'Combination',
            display : 'nodemetric_combination_label',
        },
        nodemetric_condition_comparator    : {
            label   : 'Comparator',
            type    : 'select',
            options   : comparators,
        },
        nodemetric_condition_threshold: {
            label   : 'Threshold',
            type    : 'text',
        },
        nodemetric_condition_service_provider_id:{
            type: 'hidden',
            value: elem_id,
        }
    };
    var service_opts    = {
        title       : ((editid === undefined) ? 'Create' : 'Edit') + ' a Condition',
        name        : 'nodemetriccondition',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            if (editid !== undefined) {
                $.ajax({
                    url     : '/api/nodemetriccondition/' + editid + '/updateName',
                    type    : 'POST'
                });
            }
            $('#service_ressources_nodemetric_conditions_' + elem_id).trigger('reloadGrid');
        }
    };
    if (editid !== undefined) {
        service_opts.id = editid;
        service_opts.fields.nodemetric_condition_label.type = 'hidden';
    }
    (new ModalForm(service_opts)).start();
}
function createNodemetricCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add condition'});
    button.bind('click', function() {
        nodemetricconditionmodal(elem_id);
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
        title       : 'Create a Rule',
        name        : 'nodemetricrule',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a rule'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
  
    ////////////////////////////////////// Node Rule Forumla Construciton ///////////////////////////////////////////
        
        $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/nodemetriccondition?dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].nodemetric_condition_label, value : answer.rows[row].nodemetric_condition_id});

                });
            }
    });

    function split( val ) {
			return val.split( / \s*/ );
		}
	    function extractLast( term ) {
			return split( term ).pop();
		}

		$( "#input_nodemetric_rule_formula" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				minLength: 0,
				source: function( request, response ) {
					// delegate back to autocomplete, but extract the last term
					response( $.ui.autocomplete.filter(
						availableTags, extractLast( request.term ) ) );
				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					terms.push( "id" + ui.item.value );
					// add placeholder to get the comma-and-space at the end
					//terms.push( "" );
					this.value = terms;
					this.value = terms.join(" ");
					return false;
				}
			});
	});
    ////////////////////////////////////// END OF : Node Rule Forumla Construciton ///////////////////////////////////////////
  
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function serviceconditionmodal(elem_id, editid) {
    var service_fields  = {
        aggregate_condition_label    : {
            label   : 'Name',
            type    : 'text',
        },
        aggregate_combination_id    :{
            label   : 'Combination',
            display : 'aggregate_combination_label',
        },
        comparator  : {
            label   : 'Comparator',
            type    : 'select',
            options : comparators,
        },
        threshold:{
            label   : 'Threshold',
            type    : 'text',
        },
        state:{
            label   : 'Enabled',
            type    : 'select',
            options   : rulestates,
        },
        aggregate_condition_service_provider_id	:{
            type    : 'hidden',
            value   : elem_id,
        },
    };
    var service_opts    = {
        title       : ((editid === undefined) ? 'Create' : 'Edit') + ' a Service Condition',
        name        : 'aggregatecondition',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            if (editid !== undefined) {
                $.ajax({
                    url     : '/api/aggregatecondition/' + editid + '/updateName',
                    type    : 'POST'
                });
            }
            $('#service_ressources_aggregate_conditions_' + elem_id).trigger('reloadGrid');
        }
    };
    if (editid !== undefined) {
        service_opts.id = editid;
        service_opts.fields.aggregate_condition_label.type  = 'hidden';
    }
    (new ModalForm(service_opts)).start();
}

function createServiceCondition(container_id, elem_id) {
    var button = $("<button>", {html : 'Add a Service Condition'});
    button.bind('click', function() {
        serviceconditionmodal(elem_id);
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceRule(container_id, elem_id) {
		
	var loadServicesMonitoringGridId = 'service_rule_creation_condition_listing_' + elem_id;
    create_grid( {
        url: '/api/nodemetriccondition',
        content_container_id: 'service_condition_listing_for_service_rule_creation',
        grid_id: loadServicesMonitoringGridId,
        colNames: [ 'id', 'name' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 90 },
        ],
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
        aggregate_rule_formula :{
            label   : 'Formula',
            type    : 'text',
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
        title       : 'Create a Rule',
        name        : 'aggregaterule',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };

    var button = $("<button>", {html : 'Add a Rule'});
  	button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
        
    
    ////////////////////////////////////// Service Rule Forumla Construciton ///////////////////////////////////////////
    $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/aggregatecondition?dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].aggregate_condition_label, value : answer.rows[row].aggregate_condition_id});

                });
                availableTags.join("AND","OR");
            }
    });

    function split( val ) {
			return val.split( / \s*/ );
		}
	    function extractLast( term ) {
			return split( term ).pop();
		}

		$( "#input_aggregate_rule_formula" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				minLength: 0,
				source: function( request, response ) {
					// delegate back to autocomplete, but extract the last term
					response( $.ui.autocomplete.filter(
						availableTags, extractLast( request.term ) ) );
				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					terms.push( "id" + ui.item.value );
					// add placeholder to get the comma-and-space at the end
					//terms.push( "" );
					this.value = terms;
					this.value = terms.join(" ");
					return false;
				}
			});
	});
    //////////////////////////////////////  END OF : Service Rule Forumla Construciton ///////////////////////////////////////////
    
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
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
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
            // Rules State
            $.ajax({
                url     : '/api/aggregaterule?aggregate_rule_service_provider_id=' + rowelem.pk,
                type    : 'GET',
                success : function(aggregaterules) {
                    var verified    = 0;
                    var undef       = 0;
                    var ok          = 0;
                    for (var i in aggregaterules) if (aggregaterules.hasOwnProperty(i)) {
                        var lasteval    = aggregaterules[i].aggregate_rule_last_eval;
                        if (lasteval === '1') {
                            ++verified;
                        } else if (lasteval === null) {
                            ++undef;
                        } else if (lasteval === '0') {
                            ++ok;
                        }
                        var cellContent = $('<div>');
                        if (ok > 0) {
                            $(cellContent).append($('<img>', { src : '/images/icons/up.png' })).append(ok + "&nbsp;");
                        }
                        if (verified > 0) {
                            $(cellContent).append($('<img>', { src : '/images/icons/broken.png' })).append(verified + "&nbsp;");
                        }
                        if (undef > 0) {
                            $(cellContent).append($('<img>', { src : '/images/icons/down.png' })).append(undef);
                        }
                        $(grid).setCell(rowid, 'rulesstate', cellContent.html());
                    }
                }
            });
        },
        rowNum : 25,
        colNames: [ 'ID', 'Name', 'Enabled', 'Rules State', 'Node Number' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'externalcluster_name', index: 'service_name', width: 200 },
            { name: 'externalcluster_state', index: 'service_state', width: 90, formatter:StateFormatter },
            { name: 'rulesstate', index : 'rulesstate' },
            { name: 'node_number', index: 'node_number', width: 150 }
        ],
        elem_name : 'service',
    });
    
    $("#services_list").on('gridChange', reloadServices);
    
    createAddServiceButton(container);
}

function createUpdateNodeButton(container, elem_id, grid) {
    var button = $("<button>", { text : 'Update Nodes' }).button({ icons : { primary : 'ui-icon-refresh' } });
    // Check if there is a configured directory service
    if (isThereAConnector(elem_id, 'DirectoryService') === true) {
        $(button).bind('click', function(event) {
            var dialog = $("<div>", { css : { 'text-align' : 'center' } });
            dialog.append($("<label>", { for : 'adpassword', text : 'Please enter your password :' }));
            dialog.append($("<input>", { id : 'adpassword', name : 'adpassword', type : 'password' }));
            dialog.append($("<div>", { id : "adpassworderror", class : 'ui-corner-all' }));
            // Create the modal dialog
            $(dialog).dialog({
                modal           : true,
                title           : "Update service nodes",
                resizable       : false,
                draggable       : false,
                closeOnEscape   : false,
                buttons         : {
                    'Ok'    : function() {
                        $("div#adpassworderror").removeClass("ui-state-error").empty();
                        var waitingPopup    = $("<div>", { text : 'Waiting...' }).css('text-align', 'center').dialog({
                            draggable   : false,
                            resizable   : false,
                            onClose     : function() { $(this).remove(); }
                        });
                        $(waitingPopup).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
                        var passwd          = $("input#adpassword").attr('value');
                        var ok              = false;
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
                                    $(waitingPopup).dialog('close');
                                    // Ugly but there is no other way to differentiate error from confirm messages for now
                                    if ((new RegExp("^## EXCEPTION")).test(data.msg)) {
                                        $("input#adpassword").val("");
                                        $("div#adpassworderror").text(data.msg).addClass('ui-state-error');
                                    } else {
                                        ok  = true;
                                    }
                                }
                            });
                            // If the form succeed, then we can close the dialog
                            if (ok === true) {
                                $(grid).trigger("reloadGrid");
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

    dash_div.hide();
    container.append(dash_header);
    container.append(dash_div);
    //container.append(dash_template);

    // Needed to have the container with a good height
    container.css('overflow', 'hidden');

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
            var ctnr    = $("<div>", { id : 'connectorslistcontainer', 'class' : 'details_section' });
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
                var confButton  = $("<a>", { text : 'Configure', rel : data.rows[row].pk, 'class' : 'no-margin' });
                var delButton   = $("<a>", { text : 'Delete', rel : data.rows[row].pk, 'class' : 'no-margin' });
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
            var ctnr    = $("<div>", { id : "managerslistcontainer", 'class' : 'details_section' });
            $(ctnr).appendTo($(container));
            var table   = $("<table>", { id : 'managerslist' }).prependTo($(ctnr));
            $(table).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Managers" })));

            for (var i in data) if (data.hasOwnProperty(i)) {
                $.ajax({
                  url       : '/api/entity/' + data[i].manager_id,
                  success   : function(mangr) {
                        $.ajax({
                            url     : '/api/serviceprovider/' + mangr.service_provider_id,
                            success : function(sp) {
                                $(table).append($("<tr>", { text : data[i].manager_type + " : " + sp.externalcluster_name }));
                            }
                        });
                  }
                });
            }

            if (isThereAManager(elem_id, 'WorkflowManager') === false) {
                var addManagerButton    = $("<a>", { text : 'Add a Workflow Manager' }).button({ icons : { primary : 'ui-icon-plusthick' } });
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
                                title           : 'Add a workflow manager',
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

        }
    });

}

function loadServicesRessources (container_id, elem_id) {
    var loadServicesRessourcesGridId = 'service_ressources_list_' + elem_id;
    var serviceressources;
    $.ajax({
        url     : '/api/nodemetricrule?nodemetric_rule_service_provider_id=' + elem_id,
        success : function(data) {
            serviceressources   = data;
        }
    });
    create_grid( {
        url: '/api/externalnode?outside_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesRessourcesGridId,
        grid_class: 'service_ressources_list',
        rowNum : 25,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            for (var i in serviceressources) if (serviceressources.hasOwnProperty(i)) {
                var     ok          = $('<span>', { text : 0, rel : 'ok' });
                var     notok       = $('<span>', { text : 0, rel : 'notok' });
                var     undef       = $('<span>', { text : 0, rel : 'undef' });
                var     cellContent = $('<div>');
                $(cellContent).append($('<img>', { rel : 'ok', src : '/images/icons/up.png' })).append(ok);
                $(cellContent).append($('<img>', { rel : 'notok', src : '/images/icons/broken.png' })).append(notok);
                $(cellContent).append($('<img>', { rel : 'undef', src : '/images/icons/down.png' })).append(undef);
                $.ajax({
                    url         : '/api/nodemetricrule/' + serviceressources[i].pk + '/isVerifiedForANode',
                    type        : 'POST',
                    contentType : 'application/json',
                    data        : JSON.stringify({ 'externalcluster_id' : 67, 'externalnode_id' : rowdata.pk }),
                    success     : function(data) {
                        if (parseInt(data) === 0) {
                            $(ok).text(parseInt($(ok).text()) + 1);
                        } else if (parsenInt(data) === 1) {
                            $(notok).text(parseInt($(ok).text()) + 1);
                        } else if (data === null) {
                            $(undef).text(parseInt($(ok).text()) + 1);
                        }
                        if (parseInt($(ok).text()) <= 0) { $(cellContent).find('*[rel="ok"]').css('display', 'none'); } else { $(cellContent).find('*[rel="ok"]').css('display', 'inline'); }
                        if (parseInt($(notok).text()) <= 0) { $(cellContent).find('*[rel="notok"]').css('display', 'none'); } else { $(cellContent).find('*[rel="notok"]').css('display', 'inline'); }
                        if (parseInt($(undef).text()) <= 0) { $(cellContent).find('*[rel="undef"]').css('display', 'none'); } else { $(cellContent).find('*[rel="undef"]').css('display', 'inline'); }
                        $(grid).setCell(rowid, 'rulesstate', $(cellContent).html());
                    }
                });
            }
        },
        colNames: [ 'id', 'enabled', 'hostname', 'Rules State' ],
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

// This function load grid with list of rules for verified state corelation with the the selected node :
function node_rules_tab(cid, eid, service_provider_id) {
    

    function verifiedNodeRuleStateFormatter(cell, options, row) {
    
    //console.log(eid);
    
        var VerifiedRuleFormat;
        // Where rowid = rule_id
        $.ajax({
             url: '/api/externalnode/' + eid + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + row.pk,
             async: false,
             success: function(answer) {
                if (answer.length == 0) {
                    VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                } else if (answer[0].verified_noderule_state == 'verified') {
                    VerifiedRuleFormat = "<img src='/images/icons/broken.png' title='broken' />"
                } else if (answer[0].verified_noderule_state == 'undef') {
                    VerifiedRuleFormat = "<img src='/images/icons/down.png' title='down' />";
                }
              }
        });
        return VerifiedRuleFormat;
    }

    var loadNodeRulesTabGridId = 'node_rules_tabs';
    create_grid( {
        url: '/api/nodemetricrule?nodemetric_rule_service_provider_id=' + service_provider_id,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'node_rules_tab',
        colNames: [ 'id', 'rule', 'state' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_rule_label', index: 'nodemetric_rule_label', width: 90,},
            { name: 'nodemetric_rule_state', index: 'nodemetric_rule_state', width: 200, formatter: verifiedNodeRuleStateFormatter },
        ],
        action_delete : 'no',
    } );
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

    // Nodemetric bargraph details handler
    function nodeMetricDetailsBargraph(cid, nodeMetric_id) {
      // Use dashboard widget outside of the dashboard
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_nodes_bargraph.html', function() {
          $('.indicator_dropdown').remove();
          showNodemetricCombinationBarGraph(graph_div, nodeMetric_id, '', elem_id);
      });
    }

    // Nodemetric histogram details handler
    function nodeMetricDetailsHistogram(cid, nodeMetric_id) {
      // Use dashboard widget outside of the dashboard
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_nodes_histogram.html', function() {
          $('.indicator_dropdown').remove();
          $('.part_number_input').remove();
          showNodemetricCombinationHistogram(graph_div, nodeMetric_id, '', 10, elem_id);
      });
    }

    // Clustermetric historical graph details handler
    function clusterMetricDetailsHistorical(cid, clusterMetric_id) {
      // Use dashboard widget outside of the dashboard
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_historical_service_metric.html', function() {
          $('.clustermetric_options').remove();
          showCombinationGraph(graph_div, clusterMetric_id, '', '', '', elem_id);
      });
    }

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
        colNames: [ 'id', 'name', 'indicators formula' ],
        colModel: [ 
            { name: 'pk', index: 'pk', width: 90, sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_combination_label', index: 'nodemetric_combination_label', width: 120 },
            { name: 'nodemetric_combination_formula', index: 'nodemetric_combination_formula', width: 170 },
        ],
        details: {
            tabs : [
                    { label : 'Nodes graph', id : 'nodesgraph', onLoad : nodeMetricDetailsBargraph },
                    { label : 'Histogram', id : 'histogram', onLoad : nodeMetricDetailsHistogram },
                ],
            title : { from_column : 'nodemetric_combination_label' }
        },
        action_delete: {
            url : '/api/nodemetriccombination',
        }
    } );
    createNodemetricCombination('node_monitoring_accordion_container', elem_id);


	$('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_monitoring_accordion_container">').appendTo(divacc);
   
    var loadServicesMonitoringGridId = 'service_ressources_clustermetrics_' + elem_id;
    create_grid( {
        caption : 'Metrics',
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
        ],
        action_delete: {
            url : '/api/clustermetric',
        },
    } );
    createServiceMetric('service_monitoring_accordion_container', elem_id);
    
    $("<p>").appendTo('#service_monitoring_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_combinations_' + elem_id;
    create_grid( {
        caption: 'Metric combinations',
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
        ],
        details: {
            tabs : [
                    { label : 'Historical graph', id : 'servicehistoricalgraph', onLoad : clusterMetricDetailsHistorical },
                ],
            title : { from_column : 'aggregate_combination_label' }
        },
        action_delete: {
            url : '/api/aggregatecombination',
        },
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
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_conditions_' + elem_id;
    create_grid( {
        caption: 'Conditions',
        url: '/api/externalcluster/' + elem_id + '/nodemetric_conditions',
        content_container_id: 'node_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid, rowdata) {
            $.ajax({
                url     : '/api/nodemetriccombination/' + rowdata.nodemetric_condition_combination_id,
                success : function(data) {
                    $(grid).setCell(rowid, 'nodemetric_condition_combination_id', data.nodemetric_combination_label);
                }
            });
        },
        colNames: [ 'id', 'name', 'combination', 'comparator', 'threshold' ],
        colModel: [
            { name: 'pk', index: 'pk', sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_condition_label', index: 'nodemetric_condition_label', width: 120 },
            { name: 'nodemetric_condition_combination_id', index: 'nodemetric_condition_combination_id', width: 60 },
            { name: 'nodemetric_condition_comparator', index: 'nodemetric_condition_comparator', width: 60,},
            { name: 'nodemetric_condition_threshold', index: 'nodemetric_condition_threshold', width: 190 },
        ],
        details: { onSelectRow : function(eid) { nodemetricconditionmodal(elem_id, eid); } },
        action_delete: {
            url : '/api/nodemetriccondition',
        },
    } );
    createNodemetricCondition('node_accordion_container', elem_id)
    
    // Display nodemetric rules
    $("<p>").appendTo('#node_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_rules_' + elem_id;
    create_grid( {
        caption: 'Rules',
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
            { name: 'nodemetric_rule_state', index: 'nodemetric_rule_state', width: 60,},
            { name: 'nodemetric_rule_description', index: 'nodemetric_rule_description', width: 120 },
            { name: 'nodemetric_rule_formula', index: 'nodemetric_rule_formula', width: 120 },
        ],
        details: {
            tabs : [
                        { label : 'Overview', id : 'overview', onLoad : function(cid, eid) {
                            $.ajax({
                                url     : '/api/nodemetricrule/' + eid,
                                success : function(data) {
                                    var container   = $('#' + cid);
                                    $(container).prepend($('<p>', { text : data.nodemetric_rule_label + " : " + data.nodemetric_rule_description }));
                                }
                            });
                            require('KIO/workflows.js');
                            createWorkflowRuleAssociationButton(cid, eid, 1, elem_id);
                        }},
                        { label : 'Nodes', id : 'nodes', onLoad : function(cid, eid) { rule_nodes_tab(cid, eid, elem_id); } },
                    ],
            title : { from_column : 'nodemetric_rule_label' }
        },
        action_delete: {
            url : '/api/nodemetricrule',
        },
    } );
    
    createNodemetricRule('node_accordion_container', elem_id);
	// Here's the second part of the accordion :
    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_accordion_container">').appendTo(divacc);
    // Display service conditions :
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_conditions_' + elem_id;
    create_grid( {
        caption: 'Conditions',
        url: '/api/externalcluster/' + elem_id + '/aggregate_conditions',
        content_container_id: 'service_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            $.ajax({
                url     : '/api/aggregatecombination/' + rowdata.aggregate_combination_id,
                success : function(data) {
                    $(grid).setCell(rowid, 'aggregate_combination_id', data.aggregate_combination_label);
                }
            });
        },
        colNames: ['id','name', 'enabled', 'combination', 'comparator', 'threshold'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_condition_label',index:'aggregate_condition_label', width:120,},
             {name:'state',index:'state', width:60,},
             {name:'aggregate_combination_id',index:'aggregate_combination_id', width:60,},
             {name:'comparator',index:'comparator', width:160,},
             {name:'threshold',index:'threshold', width:60,},
           ],
        details: { onSelectRow : function(eid) { serviceconditionmodal(elem_id, eid); } }
    } );
    createServiceCondition('service_accordion_container', elem_id);
    // Display services rules :
    $("<p>").appendTo('#service_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_rules_' + elem_id;
    create_grid( {
        caption: 'Rules',
        url: '/api/externalcluster/' + elem_id + '/aggregate_rules',
        grid_class: 'service_ressources_aggregate_rules',
        content_container_id: 'service_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        colNames: ['id','name', 'enabled', 'last eval', 'formula', 'description'],
        colModel: [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'aggregate_rule_label',index:'aggregate_rule_label', width:90,},
             {name:'aggregate_rule_state',index:'aggregate_rule_state', width:90,},
             {name:'aggregate_rule_last_eval',index:'aggregate_rule_last_eval', width:90, formatter : lastevalStateFormatter},
             {name:'aggregate_rule_formula',index:'aggregate_rule_formula', width:90,},
             {name:'aggregate_rule_description',index:'aggregate_rule_description', width:200,},
           ],
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/aggregaterule/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'aggregate_rule_formula');
        },
        details : {
            tabs    : [
                { label : 'Overview', id : 'overview', onLoad : function(cid, eid) {
                    $.ajax({
                        url     : '/api/aggregaterule/' + eid,
                        success : function(data) {
                            var container   = $('#' + cid);
                            $(container).prepend($('<p>', { text : data.aggregate_rule_label + " : " + data.aggregate_rule_description }));
                        }
                    });
                    require('KIO/workflows.js');
                    createWorkflowRuleAssociationButton(cid, eid, 2, elem_id);
               }},
            ],
            title   : { from_column : 'aggregate_rule_label' }
        },
        action_delete: {
            url : '/api/aggregaterule',
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


// This function load a grid with the list of current service's nodes for state corelation with rules
function rule_nodes_tab(cid, rule_id, service_provider_id) {
    
    function verifiedRuleNodesStateFormatter(cell, options, row) {
        var VerifiedRuleFormat;
            // Where rowid = rule_id
            
            $.ajax({
                 url: '/api/externalnode/' + row.pk + '/verified_noderules?verified_noderule_nodemetric_rule_id=' + rule_id,
                 async: false,
                 success: function(answer) {
                    if (answer.length == 0) {
                        VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                    } else if (answer[0].verified_noderule_state == undefined) {
                        VerifiedRuleFormat = "<img src='/images/icons/up.png' title='up' />";
                    } else if (answer[0].verified_noderule_state == 'verified') {
                        VerifiedRuleFormat = "<img src='/images/icons/broken.png' title='broken' />";
                    } else if (answer[0].verified_noderule_state == 'undef') {
                        VerifiedRuleFormat = "<img src='/images/icons/down.png' title='down' />";
                    }
                  }
            });
        return VerifiedRuleFormat;
    }
//         url: '/api/externalnode/' + eid,
    
    var loadNodeRulesTabGridId = 'rule_nodes_tabs';
    create_grid( {
        url: '/api/externalnode?outside_id=' + service_provider_id,
        content_container_id: cid,
        grid_id: loadNodeRulesTabGridId,
        grid_class: 'rule_nodes_grid',
        colNames: [ 'id', 'hostname', 'state' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'externalnode_hostname', index: 'externalnode_hostname', width: 110,},
            { name: 'verified_noderule_state', index: 'verified_noderule_state', width: 60, formatter: verifiedRuleNodesStateFormatter,}, 
        ],
        action_delete : 'no',
    } );
}
