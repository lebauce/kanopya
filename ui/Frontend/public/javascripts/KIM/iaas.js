function load_iaas_detail_hypervisor (container_id, elem_id) {
    var container = $('#' + container_id);
    $('<div>Hypervisor for iaas ID = ' + elem_id + '<div>').appendTo(container);
    create_grid( {
        url: '/api/host',
        content_container_id: container_id,
        grid_id: 'iaas_hyp_list',
        colNames: [ 'ID', 'Base hostname', 'Initiator name' ],
        colModel: [ 
            { name: 'entity_id', index: 'entity_id', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'host_hostname', index: 'host_hostname', width: 90, sorttype: "date" },
            { name: 'host_initiatorname', index: 'host_initiatorname', width: 200 }
        ]
    } );
}

function load_iaas_content (container_id) {
    require('common/formatters.js');
    $.ajax({
        url         : '/api/serviceprovider/getServiceProviders',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ category : 'Cloudmanager' }),
        success     : function(data) {
            var iaas    = [];
            $.ajax({
                url         : '/api/serviceprovider/findManager',
                type        : 'POST',
                contentType : 'application/json',
                data        : JSON.stringify({ category : 'Cloudmanager' }),
                success     : function(managers) {
                    for (var i in data) if (data.hasOwnProperty(i)) {
                        for (var j in managers) if (managers.hasOwnProperty(j)) {
                            if (managers[j].service_provider_id === data[i].pk) {
                                if (managers[j].host_type === "Virtual Machine") {
                                    data[i].cloudmanager    = managers[j];
                                    iaas.push(data[i]);
                                }
                                break;
                            };
                        }
                    }
                    create_grid({
                        data                    : iaas,
                        content_container_id    : container_id,
                        grid_id                 : 'iaas_list',
                        colNames                : [ 'ID', 'Name', 'State' ],
                        colModel                : [
                            { name : 'id', index : 'pk', width : 60, sorttype : 'int', hidden : true, key : true },
                            { name : 'cluster_name', index : 'cluster_name', width : 200 },
                            { name : 'cluster_state', index : 'cluster_state', width : 200, formatter : StateFormatter }
                        ]
                    });
                }
            });
        }
    });
}
