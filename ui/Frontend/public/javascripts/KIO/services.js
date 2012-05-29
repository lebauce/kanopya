$.validator.addMethod("regex", function(value, element, regexp) {
    var re = new RegExp(regexp);
    return this.optional(element) || re.test(value);
}, "Please check your input");
 
// Check if there is a configured directory service
function isThereAConnector(elem_id, connector_category) {
    var is	= false;
    
    // Get all configured connectors on the service
    $.ajax({
	async	: false,
	url	: '/api/connector?service_provider_id=' + elem_id,
	success	: function(connectors) {
	    for (i in connectors) if (connectors.hasOwnProperty(i)) {
		// Get the connector type for each
		$.ajax({
		    async	: false,
		    url		: '/api/connectortype?connector_type_id=' + connectors[i].connector_type_id,
		    success	: function(data) {
			// If this is a Directory Service, then we can return true
			if (data[0].connector_category === connector_category) {
			    is	= true;
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

function createMonitoringDialog(elem_id, firstDialog) {
    function createScomDialog(elem) {
	var scom_fields = {
	    scom_ms_name        : {
		label   : 'Root Management Server FQDN'
	    },
	    scom_usessl         : {
		label   : 'Use SSL ?',
		type    : 'checkbox'
	    },
	    service_provider_id : {
		label   : '',
		type    : 'hidden',
		value   : elem_id
	    }
	};
	var scom_opts   = {
	    title       : 'Add a Monitoring Service',
	    name        : 'scom',
	    fields      : scom_fields,
	}
	if (elem !== undefined) {
	    scom_opts.prependElement = elem;
	}
	if (firstDialog) {
	    scom_opts.skippable = true;
	    scom_opts.title	= 'Step 3 of 3 : ' + scom_opts.title;
	}
	return new ModalForm(scom_opts);
    }
  
    var SCOMMod;
    var select  = $("<select>");
    var options;
    $.ajax({
	async   : false,
	type    : 'get',
	url     : '/api/connectortype?connector_category=MonitoringService',
	success : function(data) {
	    options = data;
	}
    });
    for (option in options) {
	option = options[option];
	$(select).append($("<option>", { value : option.pk, text : option.connector_name }));
    }
    $(select).bind('change', function(event) {
	var newMod;
	switch(event.currentTarget.value) {
	    case '2':
		newMod = createScomDialog();
		break;
	}
	$(SCOMMod.form).remove();
	SCOMMod.form = newMod.form;
	SCOMMod.handleArgs(newMod.exportArgs());
	$(SCOMMod.content).append(ADMod.form);
	SCOMMod.startWizard();
    });
    SCOMMod   = createScomDialog(select);
    return SCOMMod;
}

function createDirectoryDialog(elem_id, firstDialog) {
    function createADDialog(elem) {
	var ad_fields   = {
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
	    },
	    service_provider_id : {
		label   : '',
		type    : 'hidden',
		value   : elem_id
	    }
	};
	var ad_opts     = {
	    title       : 'Add an Directory Service',
	    name        : 'activedirectory',
	    fields      : ad_fields
	};
	if (elem !== undefined) {
	    ad_opts.prependElement = elem;
	}
	if (firstDialog) {
	    ad_opts.skippable	= true;
	    ad_opts.callback	= function() { createMonitoringDialog(elem_id, firstDialog).start(); };
	    ad_opts.title	= 'Step 2 of 3 : ' + ad_opts.title;
	}
	return new ModalForm(ad_opts);
    }
 
    var ADMod;
    select  = $("<select>");
    var options;
    $.ajax({
	async   : false,
	type    : 'get',
	url     : '/api/connectortype?connector_category=DirectoryService',
	success : function(data) {
	    options = data;
	}
    });
    for (option in options) {
	option = options[option];
	$(select).append($("<option>", { value : option.pk, text : option.connector_name }));
    }
    $(select).bind('change', function(event) {
	var newMod;
	switch(event.currentTarget.value) {
	    case '1':
		newMod = createADDialog();
		break;
	}
	$(ADMod.form).remove();
	ADMod.form = newMod.form;
	ADMod.handleArgs(newMod.exportArgs());
	$(ADMod.content).append(ADMod.form);
	ADMod.startWizard();
    });
    ADMod   = createADDialog(select);
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
	callback    : function(data) {
	    reloadServices();
	    createDirectoryDialog(data.pk, true).start();
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
		modal		: true,
		title		: "Update service nodes",
		resizable		: false,
		draggable		: false,
		closeOnEscape	: false,
		buttons		: {
		    'Ok'	: function() {
			var passwd 	= $("input#adpassword").attr('value');
			var ok		= false;
			// If a password was typen, then we can submit the form
			if (passwd !== "" && passwd !== undefined) {
			    $.ajax({
				url	: '/kio/services/' + elem_id + '/nodes/update',
				type	: 'post',
				async	: false,
				data	: {
				    password	: passwd
				},
				success	: function(data) {
				    ok	= true;
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
	var b	= $("<button>", { text : 'Add a Directory Service' });
	b.bind('click', function() { createDirectoryDialog(elem_id).start(); });
	b.appendTo(container);
    }
    
    if (isThereAConnector(elem_id, 'MonitoringService') === false) {
	var bu	= $("<button>", { text : 'Add a Monitoring Service' });
	bu.bind('click', function() { createMonitoringDialog(elem_id).start(); });
	bu.appendTo(container);
    }
    
    $.ajax({
 		url: '/api/connector?dataType=jqGrid&service_provider_id=' + elem_id,
 		success: function(data) {
			$(data.rows).each(function(row) {
				if ( data.rows[row].service_provider_id == elem_id ) {
    				ad_nodes_base_dn = data.rows[row].class_type_id;
    				$('<div>Connectors for Service ' + ad_nodes_base_dn + '<div>').appendTo(container);
    			}
    		});
    	}
	});
	
}

function loadServicesRessources (container_id, elem_id) {
	create_grid(container_id, 'service_ressources_list',
            ['ID','Base hostname', 'Initiator name'],
            [ 
             {name:'entity_id',index:'entity_id', width:60, sorttype:"int", hidden:true, key:true},
             {name:'host_hostname',index:'host_hostname', width:90, sorttype:"date"},
             {name:'host_initiatorname',index:'host_initiatorname', width:200,}
           ]);
    reload_grid('service_ressources_list', '/api/host');

    createUpdateNodeButton($('#' + container_id), elem_id);
}