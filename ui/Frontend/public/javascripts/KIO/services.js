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
}