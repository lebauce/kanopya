$.validator.addMethod("regex", function(value, element, regexp) {
    var re = new RegExp(regexp);
    return this.optional(element) || re.test(value);
}, "Please check your input");
 
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

function createSpecServDialog(provider_id, name, first, step, elem, editid) {
    var allFields   = {
        'activedirectory'   : {
            ad_host             : {
                label   : 'Domain controller name'
            },
            ad_nodes_base_dn    : {
                label   : 'Nodes container domain name'
            },
            ad_user             : {
                label   : 'User@domain'
            },
            ad_pwd              : {
                label   : 'Password',
                type    : 'password'
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
        }
    };
    var ad_opts     = {
        title           : ((editid === undefined) ? 'Add' : 'Edit') + ' a ' + ((step == 2) ? 'Directory' : 'Monitoring') + ' Service',
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
        if (step == 2) {
            ad_opts.callback    = function() {
                createMonDirDialog(provider_id, first, 3).start();
            };
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

function createMonDirDialog(elem_id, step, firstDialog) {
    var ADMod;
    select          = $("<select>");
    var options;
    var category    = (step == 2) ? 'DirectoryService' : 'MonitoringService';
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
        $(select).append($("<option>", { value : option.pk, text : option.connector_name }));
    }
    $(select).bind('change', function(event) {
        var name    = $(event.currentTarget).text().toLowerCase();
        var newMod  = createSpecServDialog(elem_id, name, firstDialog, step);
        $(ADMod.form).remove();
        ADMod.form  = newMod.form;
        ADMod.handleArgs(newMod.exportArgs());
        $(ADMod.content).append(ADMod.form);
        ADMod.startWizard();
    });
    // create the default form (activedirectory for directory and scom for monitoring)
    ADMod   = createSpecServDialog(elem_id, (step == 2) ? 'activedirectory' : 'scom', firstDialog, step, select);
    return ADMod;
}

function createAddServiceButton(container) {
    var service_fields  = {
        externalcluster_name    : {
            label   : 'Name'
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
                var dialog = $("<div>", { id : "waiting_default_insert", text : "Initializing configuration" });
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
            createMonDirDialog(data.pk, 2, true).start();
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
                 {name:'externalcluster_state',index:'service_state', width:90,},
                 ]);
    reload_grid('services_list', '/api/externalcluster');
    
    createAddServiceButton(container);
}

function createUpdateNodeButton(container, elem_id) {
    var button = $("<button>", { text : 'Update Nodes' });
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
}

function loadServicesConfig (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';
    
    if (isThereAConnector(elem_id, 'DirectoryService') === false) {
        var b   = $("<button>", { text : 'Add a Directory Service', id : 'adddirectory' });
        b.bind('click', function() { createMonDirDialog(elem_id, 2).start(); });
        b.appendTo(container);
    }
    
    if (isThereAConnector(elem_id, 'MonitoringService') === false) {
        var bu  = $("<button>", { text : 'Add a Monitoring Service', id : 'addmonitoring' });
        bu.bind('click', function() { createMonDirDialog(elem_id, 3).start(); });
        bu.appendTo(container);
    }
    
    var connector_type_id = '';
    var connector_name = '';
    $('<h2>Connectors :</h2>').appendTo(container);
 
    $.ajax({
 		url: '/api/connector?dataType=jqGrid&service_provider_id=' + elem_id,
 		success: function(data) {
			$(data.rows).each(function(row) {
				if ( data.rows[row].service_provider_id == elem_id ) {
    				ad_nodes_base_dn = data.rows[row].class_type_id;
    				connector_type_id = data.rows[row].connector_type_id;
    				
    			}
    		});
    	}
	});
	
	// Get the connectors types :
	$.ajax({
	url: '/api/connectortype?dataType=jqGrid',
	success: function(data) {
			$(data.rows).each(function(row) {
				if ( data.rows[row].pk == connector_type_id ) {
					connector_name = data.rows[row].connector_name;
					$('<div><table><tr>' + connector_name + '&nbsp;Configure&nbsp;&nbsp;Delete</tr></table></div>').appendTo(container);
				}
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
             {name:'externalnode_state',index:'externalnode_state', width:90,formatter:extNodeStateFormatter},
             {name:'externalnode_hostname',index:'externalnode_hostname', width:200,},
           ]);
    reload_grid('service_ressources_list', '/api/host');

    createUpdateNodeButton($('#' + container_id), elem_id);
    reload_grid(loadServicesRessourcesGridId,'/api/externalnode?outside_id=' + elem_id);
    
    // Set the correct state icon for each element :
	function extNodeStateFormatter(cell, options, row) {
		if (cell == 'up') {
			return "<img src='/images/icons/up.png' title='up' />";
		} else {
			return "<img src='/images/icons/broken.png' title='broken' />";
		}
	}
    $('service_ressources_list').jqGrid('setGridWidth', $(container_id).parent().width()-20);
   
}

function loadServicesMonitoring(container_id, elem_id) {
	var loadServicesMonitoringGridId = 'service_ressources_monitoring_' + elem_id;
	create_grid(container_id, loadServicesMonitoringGridId,
            ['id','name', 'indicator'],
            [ 
             {name:'pk',index:'pk', width:60, sorttype:"int", hidden:true, key:true},
             {name:'clustermetric_label',index:'clustermetric_label', width:90,},
             {name:'clustermetric_indicator_id',index:'clustermetric_indicator_id', width:200,},
           ]);
    reload_grid(loadServicesMonitoringGridId,'/api/externalcluster/' + elem_id + '/clustermetrics');
}