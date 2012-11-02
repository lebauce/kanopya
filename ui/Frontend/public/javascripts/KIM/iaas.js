require('KIM/services.js');

/* Temporary redefinition of a nested function of KIM/services.js */
function NodeIndicatorDetailsHistorical(cid, node_id, elem_id) {
    var cont = $('#' + cid);
    var graph_div = $('<div>', { 'class' : 'widgetcontent' });
    cont.addClass('widget');
    cont.append(graph_div);
    graph_div.load('/widgets/widget_historical_node_indicator.html', function() {
        initNodeIndicatorWidget(cont, elem_id, node_id);
    });
}

function vmdetails(spid) {
    return {
        tabs : [
            { label : 'General', id : 'generalnodedetails', onLoad : nodedetailsaction },
            { label : 'Network Interfaces', id : 'iface', onLoad : function(cid, eid) {node_ifaces_tab(cid, eid); } },
            { label : 'Monitoring', id : 'resource_monitoring', onLoad : function(cid, eid) { NodeIndicatorDetailsHistorical(cid, eid, spid); } },
            { label : 'Rules', id : 'rules', onLoad : function(cid, eid) { node_rules_tab(cid, eid, spid); } },
        ],
        title : { from_column : 'externalnode_hostname' }
    };
}

function load_iaas_detail_hypervisor (container_id, elem_id) {
    var container = $('#' + container_id);
    var cloudmanagerid  = $('#iaas_list').jqGrid('getRowData', elem_id)['cloudmanager.pk'];
    if (cloudmanagerid == null) {
        return;
    }
    $.ajax({
        url     : '/api/entity/' + cloudmanagerid + '/hypervisors',
        type    : 'POST',
        success : function(data) {
            var topush  = [];
            for (var i in data) if (data.hasOwnProperty(i)) {
                data[i].id      = data[i].pk;
                data[i].parent  = null;
                data[i].level   = '0';
                data[i].type    = 'hypervisor';
                data[i].vmcount = 0;
                $.ajax({
                    async       : false,
                    url         : '/api/host/' + data[i].id + '/virtual_machines',
                    type        : 'POST',
                    contentType : 'application/json',
                    data        : JSON.stringify({ }),
                    success     : function(hyp) {
                        return (function(vms) {
                            hyp.totalRamUsed    = 0;
                            hyp.totalCoreUsed   = 0;
                            if (vms.length > 0) {
                                hyp.vmcount     += vms.length
                                hyp.isLeaf      = false;
                                for (var j in vms) if (vms.hasOwnProperty(i)) {
                                    vms[j].id       = hyp.id + "_" + vms[j].pk;
                                    vms[j].isLeaf   = true;
                                    vms[j].level    = '1';
                                    vms[j].parent   = data[i].id;
                                    vms[j].type     = 'vm';
                                    hyp.totalRamUsed    += parseInt(vms[j].host_ram);
                                    hyp.totalCoreUsed   += parseInt(vms[j].host_core);
                                    topush.push(vms[j]);
                                }
                            } else {
                                hyp.isLeaf  = true;
                            }
                        });
                    }(data[i])
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
                colNames                : [ 'ID', 'Base hostname', 'State', 'Vms', 'Admin Ip', '', '', '', '', '', '' ],
                colModel                : [
                    { name : 'id', index : 'id', width : 60, sorttype : "int", hidden : true, key : true },
                    { name : 'host_hostname', index : 'host_hostname', width : 90 },
                    { name : 'host_state', index : 'host_state', width : 30, formatter : StateFormatter, align : 'center' },
                    { name : 'vmcount', index : 'vmcount', width : 30, align : 'center' },
                    { name : 'adminip', index : 'adminip', width : 100 },
                    { name : 'totalRamUsed', index : 'totalRamUsed', hidden : true },
                    { name : 'host_ram', index : 'host_ram', hidden : true },
                    { name : 'type', index : 'type', hidden : true },
                    { name : 'entity_id', index : 'entity_id', hidden : true },
                    { name : 'host_core', index : 'host_core', hidden : true },
                    { name : 'totalCoreUsed', index : 'totalCoreUsed', hidden : true }
                ],
                action_delete           : 'no',
                gridComplete            : displayAdminIps,
                details                 : {
                    tabs    : [
                        {
                            label   : 'Overview',
                            id      : 'hypervisor_detail_overview',
                            onLoad  : function(cid, eid) { load_hypervisorvm_details(cid, eid, cloudmanagerid); }
                        },
                    ]
                },
            }, 10);
        }
    });
}

function displayAdminIps() {
    var grid    = $('#iaas_hyp_list');
    var dataIds = $(grid).jqGrid('getDataIDs');
    for (var i in dataIds) if (dataIds.hasOwnProperty(i)) {
        var rowData = $(grid).jqGrid('getRowData', dataIds[i]);
        $.ajax({
            url     : '/api/host/' + rowData.entity_id,
            type    : 'GET',
            success : function(grid, rowid) {
                return function(data) {
                    $(grid).jqGrid('setCell', rowid, 'adminip', data.admin_ip);
                };
            }(grid, dataIds[i])
        });
    }
}

function load_hypervisorvm_details(cid, eid, cmgrid) {
    var data            = $('#iaas_hyp_list').jqGrid('getRowData', eid);
    if (data.type === 'hypervisor') {
        var table           = $('<table>', { width : '100%' }).appendTo($('#' + cid));
        $(table).append($('<tr>').append($('<th>', { text : 'Hostname : ', width : '100px' }))
                                     .append($('<td>', { text : data.host_hostname })));
        data.host_ram = data.host_ram / 1024 / 1024;
        data.totalRamUsed = data.totalRamUsed / 1024 / 1024;
        var hypervisorType  = $('<td>');
        $(table).append($('<tr>').append($('<th>', { text : 'Hypervisor : ' }))
                                 .append(hypervisorType))
                .append($('<tr>').append($('<th>', { text : 'RAM Used : ' }))
                                 .append($('<td>').append($('<div>').progressbar({ max : data.host_ram, value : data.totalRamUsed }))
                                                  .append($('<span>', { text : data.totalRamUsed + ' / ' + data.host_ram + ' Mo', style : 'float:right;' }))))
                .append($('<tr>').append($('<th>', { text : 'Cpu Used : ' }))
                                 .append($('<td>').append($('<div>').progressbar({ max : data.host_core, value : parseInt(data.totalCoreUsed) }))
                                                  .append($('<span>', { text : data.totalCoreUsed + ' / ' + data.host_core, style : 'float:right;' }))));
        $.ajax({
            url     : '/api/entity/' + cmgrid,
            success : function(elem) { $(hypervisorType).text(elem.hypervisor); }
        });
        $('#' + cid).append('<hr>');
        var networktable    = $('<table>', { width : '100%' }).appendTo($('#' + cid));
        $(networktable).append($('<tr>').append($('<th>', { text : 'Network type' }))
                                        .append($('<th>', { text : 'Network' }))
                                        .append($('<th>', { text : 'Pool IP' })));
        var expands = ['ifaces', 'ifaces.interface', 'ifaces.interface.interface_role',
                       'ifaces.interface.interface_networks', 'ifaces.interface.interface_networks.network',
                       'ifaces.interface.interface_networks.network.network_poolips',
                       'ifaces.interface.interface_networks.network.network_poolips.poolip',];
        $.ajax({
            url     : '/api/host/' + data.entity_id + '?expand=' + expands.join(','),
            success : function(hostdata) {
                var interfaces  = {};
                var current;
                for (var i in hostdata.ifaces) if (hostdata.ifaces.hasOwnProperty(i)) {
                    var iface   = hostdata.ifaces[i];

                    if (interfaces[iface.interface.interface_role.interface_role_name] == null) {
                        current = $('<tr>').appendTo(networktable).append($('<td>', { text : iface.interface.interface_role.interface_role_name }));
                        interfaces[iface.interface.interface_role.interface_role_name]  = current;
                    } else {
                        var tmp = $('<tr>').append('<td>');
                        $(current).after(tmp);
                        current = tmp;
                    }
                    for (var j in iface.interface.interface_networks) if (iface.interface.interface_networks.hasOwnProperty(j)) {
                        var network = iface.interface.interface_networks[j].network;
                        $(current).append($('<td>', { text : network.network_name }));
                        for (var k in network.network_poolips) if (network.network_poolips.hasOwnProperty(k)) {
                            var pip     = network.network_poolips[k].poolip;
                            var poolip  = $('<td>', {
                                text : pip.poolip_name + ' : ' + pip.poolip_addr
                            });
                            if (parseInt(k) === 0) {
                                $(current).append(poolip);
                            }
                            else {
                                var tmp = $('<tr>').append('<td>').append('<td>').append(poolip);
                                $(current).after(tmp);
                                current = tmp;
                            }
                        }
                    }
                }
            }
        });
    }
    else {
        $('#' + cid).parents('.ui-dialog').first().find('button').first().trigger('click');
        $.ajax({
            url     : '/api/host/' + data.entity_id + '?expand=node',
            success : function(node) {
                node    = node.node;
                show_detail('iaas_hyp_list', $('#iaas_hyp_list').attr('class'), node.pk, node, vmdetails(node.service_provider_id));
            }
        });
    }
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
                                    break;
                                }
                            }
                        }
                    }
                    var tabs    = [];
                    // Add the same tabs than 'Services'
                    jQuery.extend(true, tabs, mainmenu_def.Services.jsontree.submenu);
                    // Add the tab 'Hypervisor'
                    tabs.push({label : 'Hypervisors', id : 'hypervisors', onLoad : load_iaas_detail_hypervisor });
                    // change details tab callback to inform we are in IAAS mode
                    var details_tab = $.grep(tabs, function (e) {return e.id == 'service_details'});
                    details_tab[0].onLoad = function(cid, eid) { require('KIM/services_details.js'); loadServicesDetails(cid, eid, 1);};

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
                            noDialog    : true,
                            tabs        : tabs
                        }
                    });
                }
            });
        }
    });
}
