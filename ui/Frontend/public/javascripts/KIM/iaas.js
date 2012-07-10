function load_iaas_detail_hypervisor (container_id, elem_id) {
    var container = $('#' + container_id);
    var cloudmanagerid  = $('#iaas_list').jqGrid('getRowData', elem_id)['cloudmanager.pk'];
    if (cloudmanagerid == null) {
        return;
    }
    $.ajax({
        url     : '/api/entity/' + cloudmanagerid + '/getHypervisors',
        type    : 'POST',
        success : function(data) {
            var topush  = [];
            for (var i in data) if (data.hasOwnProperty(i)) {
                data[i].id      = data[i].pk;
                data[i].parent  = 'null';
                data[i].level   = '0';
                $.ajax({
                    async       : false,
                    url         : '/api/entity/' + cloudmanagerid + '/getVmsFromHypervisorHostId',
                    type        : 'POST',
                    contentType : 'application/json',
                    data        : JSON.stringify({ hypervisor_host_id : data[i].id }),
                    success     : function(vms) {
                        if (data.length > 0) {
                            data[i].isLeaf  = false;
                            for (var j in vms) if (vms.hasOwnProperty(i)) {
                                vms[j].id       = data[i].id + "_" + vms[j].pk;
                                vms[j].isLeaf   = true;
                                vms[j].level    = '1';
                                vms[j].parent   = data[i].id;
                                topush.push(vms[j]);
                            }
                        } else {
                            data[i].isLeaf  = true;
                        }
                    }
                });
            }
            data    = data.concat(topush);
            createTreeGrid({
                caption                 : 'Hypervisors for IaaS ' + elem_id,
                treeGrid                : true,
                treeGridModel           : 'adjacency',
                ExpandColumn            : 'host_hostname',
                data                    : data,
                content_container_id    : container_id,
                grid_id                 : 'iaas_hyp_list',
                colNames                : [ 'ID', 'Base hostname', 'Initiator name', 'State', 'Admin IP' ],
                colModel                : [ 
                    { name : 'id', index : 'id', width : 60, sorttype : "int", hidden : true, key : true },
                    { name : 'host_hostname', index : 'host_hostname', width : 90 },
                    { name : 'host_initiatorname', index : 'host_initiatorname', width : 200 },
                    { name : 'host_state', index : 'host_state', width : 30, formatter : StateFormatter },
                    { name : 'ip', index : 'ip', width : 70 }
                ],
                action_delete           : 'no'
            }, 10);
        }
    });
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
                            }
                        }
                    }
                    create_grid({
                        data                    : iaas,
                        content_container_id    : container_id,
                        grid_id                 : 'iaas_list',
                        colNames                : [ 'ID', 'Name', 'State', 'ManagerID' ],
                        colModel                : [
                            { name : 'pk', index : 'pk', width : 60, sorttype : 'int', hidden : true, key : true },
                            { name : 'cluster_name', index : 'cluster_name', width : 200 },
                            { name : 'cluster_state', index : 'cluster_state', width : 200, formatter : StateFormatter },
                            { name : 'cloudmanager.pk', index : 'cloudmanager.pk', width : 60, hidden : true, sorttype : 'int' }
                        ],
                        details                 : {
                            tabs    : [
                                {
                                    label   : 'Overview',
                                    id      : 'iaas_detail_overview',
                                    onLoad  : function() { }
                                },
                                {
                                    label   : 'Hypervisors',
                                    id      : 'iaas_detail_hypervisors',
                                    onLoad  : load_iaas_detail_hypervisor
                                }
                            ]
                        }
                    });
                }
            });
        }
    });
}
