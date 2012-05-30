
function isTheADirectoryService(elem_id) {
    var is	= false;
    
    $.ajax({
	async	: false,
	url	: '/api/connector?service_provider_id=' + elem_id,
	success	: function(connectors) {
	    for (i in connectors) if (connectors.hasOwnProperty(i)) {
		$.ajax({
		    async	: false,
		    url		: '/api/connectortype?connector_type_id=' + connectors[i].connector_type_id,
		    success	: function(data) {
			if (data[0].connector_category === 'DirectoryService') {
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

function createUpdateNodeButton(container, elem_id) {
    var button = $("<button>", { text : 'Update Nodes' });
    isTheADirectoryService(elem_id);
    if (isTheADirectoryService(elem_id) === true) {
	$(button).bind('click', function(event) {
	    var dialog = $("<div>", { css : { 'text-align' : 'center' } });
	    dialog.append($("<label>", { for : 'adpassword', text : 'Please enter your password :' }));
	    dialog.append($("<input>", { id : 'adpassword', name : 'adpassword' }));
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
    }
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
    var externalclustername = 'TORTUE !!!!';
    
    $.ajax({
 		url: '/api/externalcluster/' + elem_id + '/connectors?dataType=jqGrid',
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