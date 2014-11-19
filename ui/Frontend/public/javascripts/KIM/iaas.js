require('KIM/services.js');
require('common/lib_list.js');

function iaas_registerbutton_action(e, grid) {
    (new KanopyaFormWizard({
        title      : 'Register an OpenStack',
        type       : 'openstack',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'api_username', 'api_password', 'keystone_url', 'tenant_name', 'executor_component_id' ],
        callback   : function (iaas) {
            handleCreate(grid);

            // Raise the Iaas component synchronisation
            ajax('POST', '/api/component/' + iaas.pk + '/synchronize');
        }
    })).start();
}

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
        title : { from_column : 'node_hostname' }
    };
}

function load_iaas_detail_hypervisor (container_id, elem_id) {

    var container = $('#' + container_id);

    // Retrieve the cloud manager
    // Workaround to handle both param service_provider_id and cloudmanager_id
    // If the elem_id do not corresdonf to a service provider, elem_id is the cloudmanager
    $.ajax({
        url     : 'api/serviceprovider/'+elem_id+'/components?component_type.component_type_categories.component_category.category_name=VirtualMachineManager',
        async   : false,
        success : function(host_manager) {
            if (host_manager.length > 0) {
                elem_id = host_manager[0].pk;
            }
        }
    });

    $.ajax({
        url     : '/api/virtualization/' + elem_id + '/hypervisors?expand=node',
        type    : 'GET',
        success : function(data) {
            var topush  = [];
            for (var i in data) if (data.hasOwnProperty(i)) {
                data[i].id      = data[i].pk;
                data[i].parent  = null;
                data[i].level   = '0';
                data[i].type    = 'hypervisor';
                data[i].vmcount = 0;
                $.ajax({
                    async   : false,
                    url     : '/api/hypervisor/' + data[i].id + '/virtual_machines?expand=node',
                    success : function(hyp) {
                        return (function(vms) {
                            hyp.totalRamUsed    = 0;
                            hyp.totalCoreUsed   = 0;
                            if (vms.length > 0) {
                                hyp.vmcount     += vms.length
                                hyp.isLeaf      = false;
                                for (var j in vms) if (vms.hasOwnProperty(j)) {
                                    vms[j].id       = hyp.id + "_" + vms[j].pk;
                                    vms[j].isLeaf   = true;
                                    vms[j].level    = '1';
                                    vms[j].parent   = hyp.id;
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
                ExpandColumn            : 'node.node_hostname',
                data                    : data,
                content_container_id    : container_id,
                grid_id                 : 'iaas_hyp_list',
                colNames                : [ 'ID', 'Base hostname', 'State', 'Vms', 'Admin Ip', '', '', '', '', '', '' ],
                colModel                : [
                    { name : 'id', index : 'id', width : 60, sorttype : "int", hidden : true, key : true },
                    { name : 'node.node_hostname', index : 'node.node_hostname', width : 90 },
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
                            onLoad  : function(cid, eid) { load_hypervisorvm_details(cid, eid, elem_id); }
                        },
                        {
                            label  : 'General',
                            id     : 'generalnodedetails',
                            onLoad : function(cid, eid) { nodedetailsaction(cid, null, eid); }
                        },
                        {
                            label  : 'Network Interfaces',
                            id     : 'iface',
                            onLoad : function(cid, eid) { node_ifaces_tab(cid, null, eid); }
                        },
                    ],
                    title : { from_column : 'node.node_hostname' }
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
                                     .append($('<td>', { text : data['node.node_hostname'] })));
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

    var iaasCollection;

    function loadIaasCollection() {

        var iaasObject;
        var index, map, num;

        var stateMap = {
            'up'       : {
                'label': 'Up',
                'icon' : 'fa-thumbs-up'
            },
            'in'       : {
                'label': 'Up',
                'icon' : 'fa-thumbs-up'
            },
            'down'     : {
                'label': 'Down',
                'icon' : 'fa-thumbs-down'
            },
            'broken'   : {
                'label': 'Broken',
                'icon' : 'fa-times'
            }
        };

        iaasCollection = [];

        $.getJSON(
            '/api/component?custom.category=VirtualMachineManager&expand=component_type,service_provider&deep=1',
            function(data) {
                $.each(data, function(i, obj) {
                    iaasObject = {
                        'id'                 : obj.pk,
                        'label'              : obj.label,
                        'url'                : obj.keystone_url,
                        'urlLabel'           : '',
                        'componentTypeId'    : obj.component_type_id,
                        'componentName'      : obj.component_type.component_name.toLowerCase(),
                        'hypervisorCount'    : 0,
                        'vmCount'            : 0,
                        'cpuTotal'           : 0,
                        'cpuUsed'            : 0,
                        'ramUnit'            : 'MB',
                        'ramTotal'           : 0,
                        'ramUsed'            : 0,
                        // Necessary for detail mapping
                        'pk'                 : obj.pk,
                        'service_provider_id': obj.service_provider_id
                    };

                    if (iaasObject.url) {
                        index = iaasObject.url.search(/\d/);
                        iaasObject.urlLabel = (index > -1) ? iaasObject.url.substr(index) : iaasObject.url;
                    }

                    // State
                    if (obj.service_provider) {
                        iaasObject.state = obj.service_provider.cluster_state;
                        index = iaasObject.state.indexOf(':');
                        if (index > -1) {
                            iaasObject.state = iaasObject.state.substring(0, index);
                        }
                        if (iaasObject.state in stateMap) {
                            iaasObject.stateLabel = stateMap[iaasObject.state].label;
                            iaasObject.stateIcon = stateMap[iaasObject.state].icon;
                        }
                    }
                    if (!iaasObject.state) {
                        iaasObject.state = 'undefined';
                    }

                    // Hypervisors
                    $.ajax({
                        url     : '/api/virtualization/' + iaasObject.id + '/hypervisors?expand=node',
                        type    : 'GET',
                        dataType: 'json',
                        async   : false,
                        success: function(data) {
                            iaasObject.hypervisorCount += data.length;

                            $.each(data, function(i, obj) {
                                // Total CPU and RAM
                                num = parseInt(obj.host_core, 10);
                                iaasObject.cpuTotal += num;
                                num = parseInt(obj.host_ram, 10);
                                iaasObject.ramTotal += num;

                                // Virtual machines
                                $.ajax({
                                    url     : '/api/hypervisor/' + obj.pk + '/virtual_machines?expand=node',
                                    type    : 'GET',
                                    dataType: 'json',
                                    async   : false,
                                    success: function(data) {
                                        iaasObject.vmCount += data.length;

                                        $.each(data, function(i, obj) {
                                            // Used CPU and RAM
                                            num = parseInt(obj.host_core, 10);
                                            iaasObject.cpuUsed += num;
                                            num = parseInt(obj.host_ram, 10);
                                            iaasObject.ramUsed += num;
                                        });
                                    },
                                    error: function() {
                                        iaasObject.vmCount = '?';
                                        iaasObject.cpuUsed = '?';
                                        iaasObject.ramUsed = '?';
                                        return false; // equivalent to break for $.each
                                    }
                                });
                            });
                        },
                        error: function() {
                            iaasObject.hypervisorCount = '?';
                            iaasObject.vmCount = '?';
                            iaasObject.cpuUsed = '?';
                            iaasObject.ramUsed = '?';
                        }
                    });

                    if (!isNaN(iaasObject.ramUsed) && iaasObject.ramUsed > 0) {
                        map = getReadableSize(iaasObject.ramUsed, false);
                        iaasObject.ramUnit = map.unit;
                        iaasObject.ramUsed = map.value;
                        iaasObject.ramUsed = formatRam(iaasObject.ramUsed);
                        if(!isNaN(iaasObject.ramTotal) && iaasObject.ramTotal > 0) {
                            iaasObject.ramTotal = convertUnits(iaasObject.ramTotal, 'B', iaasObject.ramUnit.substr(0, 1));
                            iaasObject.ramTotal = formatRam(iaasObject.ramTotal);
                        }
                    } else if(!isNaN(iaasObject.ramTotal) && iaasObject.ramTotal > 0) {
                        map = getReadableSize(iaasObject.ramTotal, false);
                        iaasObject.ramUnit = map.unit;
                        iaasObject.ramTotal = map.value;
                        iaasObject.ramTotal = formatRam(iaasObject.ramTotal);
                    }

                    iaasCollection.push(iaasObject);
                });
                renderHtml();
            }
        );
    }

    function formatRam(value) {

        var index;

        if (value == parseInt(value)) {
            value = value.toString();
            index = value.indexOf('.');
            if (index > -1) {
                value = value.substring(0, index);
            }
        } else {
            value = (Math.round(value * 10)) / 10; 
            value = value.toString();
        }

        return value;
    }

    function renderHtml() {

        clear();
        renderRegisterButtons();
        renderTemplate();
    }

    function clear() {

        $('.top-action-block').remove();
        $('#' + container_id).empty();
        $('#service_dashboard').remove();
    }

    function renderRegisterButtons() {

        $('<div>', {class: 'top-action-block'})
            .append($('<a>', {
                text: 'Register an OpenStack',
                class: 'top-action openstack',
                click: function(e) {
                    iaas_registerbutton_action(e, grid);
                }
            }))
            .append($('<a>', {
                text: 'Register a vCenter',
                class: 'top-action vcenter',
                click: function(e) {
                    // iaas_registerbutton_action(e, grid);
                }
            }))
            .append($('<div>', {
                text: 'Register an AWS',
                class: 'top-action aws disabled',
                click: function(e) {
                }
            }))
            .appendTo($('#' + container_id).prev('.action_buttons'));
    }

    function renderTemplate() {

        var i;
        var templateFile = '/templates/iaas-home.tmpl.html';

        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('#' + container_id).append(template({
                'iaasCollection': iaasCollection
            }));
            for (i = 0; i < iaasCollection.length; i++) {
                renderChart(iaasCollection[i], 'cpu-chart', 'cpu', '#1D871B');
                renderChart(iaasCollection[i], 'ram-chart', 'ram', '#4E8FFF');
            }
            activateButtons();
        });
    }

    function renderChart(iaasObject, containerId, infoType, infoColor) {

        var value1, value2;
        var ratio;
        var serie;

        containerId += iaasObject.id;

        if (isNaN(iaasObject[infoType + 'Total']) || isNaN(iaasObject[infoType + 'Used']) || iaasObject[infoType + 'Total'] === 0) {
            value1 = 0;
            ratio = '';
        } else {
            value1 = Math.round(iaasObject[infoType + 'Used'] / iaasObject[infoType + 'Total'] * 100);
        }
            ratio = value1;
        value2 = 100 - value1;

        serie = [[1, value1], [2, value2]];

        // serie = [[1, 75], [2, 25]];
        // ratio = 75;

        console.debug(serie);

        $.jqplot(containerId, [serie], {
            title: {
                text: (ratio === '') ? '' : ratio + '%',
                fontSize: '9px',
            },
            seriesColors: [infoColor, '#cccccc'],
            grid: {
                shadow: false,
                background: 'transparent',
                drawBorder: false
            },
            seriesDefaults: {
                renderer:$.jqplot.DonutRenderer,
                rendererOptions:{
                    sliceMargin: 0,
                    startAngle: -90,
                    showDatatabels: false,
                    diameter: 30,
                    innerDiameter: 15,
                    shadowAlpha: 0, 
                    highlightMouseOver: false
                }
            }
        });
    }

    function activateButtons() {

        var isRunning = false;

        activateExpander();

        // Detail
        $('.list-item-info .name span').click(function() {
            $(this)
                .parents('.list-item')
                .find('.button-detail')
                .trigger('click');
        });
        $('.button-detail').click(function() {
            var id = $(this).parent().data('id');
            displayDetail(id);
        });

        // Synchronize
        $('.button-synchronize').click(function() {

            if (isRunning === true) {
                return;
            }
            isRunning = true;

            var id = $(this).parent().data('id');
            var _this = this;
            startTextButtonAnimation(_this);
            $.ajax({
                type: "POST",
                url: '/api/component/' + id + '/synchronize',
                complete: function() {
                    stopTextButtonAnimation(_this);
                    isRunning = false;
                }
            });
        });

        // Optimize
        $('.button-optimize').click(function() {

            if (isRunning === true) {
                return;
            }
            isRunning = true;

            var id = $(this).parent().data('id');
            var _this = this;
            startTextButtonAnimation(_this);
            $.ajax({
                type: "POST",
                url: '/api/component/' + id + '/optimiaas',
                complete: function() {
                    stopTextButtonAnimation(_this);
                    isRunning = false;
                }
            });
        });

        // Unregister
        $('.button-unregister').click(function() {
            var id = $(this).parent().data('id');
            confirmDelete(
                '/api/openstack/',
                id,
                null,
                {
                    'actionLabel': 'unregister',
                    'successCallback': function() {
                        reloadList();
                    }
                }
            );
        });
    }

    function reloadList() {
        load_iaas_content(container_id);
    }

    function displayDetail(iaasId) {

        var iaasObject = getIaasObjectById(iaasId);

        var details = {
            noDialog: true
        };
        if (iaasObject.service_provider_id) {
            // If the component is installed on a service provider,
            // display the service provider details with the additional
            // tab hypervisors
            details['tabs'] = tabs;
            iaasId = iaasObject.service_provider_id;

        } else {
            details['tabs'] = [hypervisors_tab];
        }

        clear();

        display_row_details(iaasId, details, iaasObject, 'content_iaas_static');
    }

    function getIaasObjectById(iaasId) {

        var iaasObject = {};

        for (var i = 0; i < iaasCollection.length; i++) {
            if (iaasCollection[i].id == iaasId) {
                iaasObject = iaasCollection[i];
                break;
            }
        }

        return iaasObject;
    }

    loadIaasCollection();

    var tabs = [];
    // Add the same tabs than 'Services'
    jQuery.extend(true, tabs, mainmenu_def.Instances.jsontree.submenu);
    // Remove the Billing tab
    for (var i = tabs.length -1; i >= 0; i--) {
        if (tabs[i].id == 'billing') {
            tabs.splice(i,1);
            break;
        }
    }
    // Add the tab 'Hypervisor'
    var hypervisors_tab = {
        label : 'Hypervisors',
        id    : 'hypervisors',
        onLoad: load_iaas_detail_hypervisor,
        icon  : 'compute'
    };
    tabs.push(hypervisors_tab);

    // change details tab callback to inform we are in IAAS mode
    var details_tab = $.grep(tabs, function (e) {
        return e.id == 'service_details'
    });
    details_tab[0].onLoad = function(cid, eid) {
        require('KIM/services_details.js');
        loadServicesDetails(cid, eid, 1);
    };

    return;
    ///////////////////////////////////////////////////////////////////////////

    require('common/formatters.js');

    var url = '/api/component?custom.category=VirtualMachineManager&expand=service_provider,nodes&deep=1';
    var grid = create_grid({
        url : url,
        content_container_id    : container_id,
        grid_id                 : 'iaas_list',
        colNames                : [ 'ID', 'ServiceProvider', 'Name', 'State', 'Active', 'Synchronize', 'Stack', 'Spread', 'Enroll' ],
        colModel                : [
            { name : 'pk', index : 'pk', width : 60, sorttype : 'int', hidden : true, key : true },
            { name : 'service_provider_id', index : 'service_provider_id', width : 60, sorttype : 'int', hidden : true },
            { name : 'label', index : 'label', width : 200 },
            { name : 'service_provider.cluster_state', index : 'cluster_state', width : 200, formatter : StateFormatter },
            { name : 'active', index: 'active', hidden : true},
            { name : 'synchronize', index : 'synchronize', width : 40, align : 'center', nodetails : true },
            { name : 'stack', index : 'stack', width : 40, align : 'center', nodetails : true },
            { name : 'spread', index : 'spread', width : 40, align : 'center', nodetails : true },
            { name : 'enroll', index : 'enroll', width : 40, align : 'center', nodetails : true },
        ],
        details : {
            onSelectRow : function(elem_id, row_data, grid_id) {
                var details = { noDialog : true };
                if (row_data.service_provider_id) {
                    // If the component is installed on a service provider,
                    // display the service provider details with the additional
                    // tab hypervisors
                    details['tabs'] = tabs;
                    elem_id = row_data.service_provider_id;
                } else {
                    details['tabs'] = [ hypervisors_tab ];
                }
                display_row_details(elem_id, details, row_data, grid_id);
            },
        },
        afterInsertRow : function(grid, rowid, rowdata, rowelem) {
            var cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="iaas_list_synchronize"]');
            var button  = $('<button>', { text : 'Sync', id : 'sync-iaas' })
                              .button({ icons : { primary : 'ui-icon-refresh' } })
                              .attr('style', 'margin-top:0;')
                              .click(function() {
                              $.ajax({
                                  url  : '/api/component/' + rowid + '/synchronize',
                                  type : 'POST'
                               });
                          });
            $(cell).append(button);
            cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="iaas_list_stack"]');
            button  = $('<button>', { text : 'Stack', id : 'stack-iaas' })
                              .button({ icons : { primary : 'ui-icon-refresh' } })
                              .attr('style', 'margin-top:0;')
                              .click(function() {
                              $.ajax({
                                  url  : '/api/component/' + rowid + '/optimiaas',
                                  type : 'POST'
                               });
                          });
            $(cell).append(button);
            cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="iaas_list_spread"]');
            button  = $('<button>', { text : 'Spread', id : 'spread-iaas' })
                              .button({ icons : { primary : 'ui-icon-refresh' } })
                              .attr('style', 'margin-top:0;')
                              .click(function() {
                              $.ajax({
                                  url  : '/api/component/' + rowid + '/optimiaas',
                                  type : 'POST',
                                  data : {'policy':'spread'}
                               });
                          });
            $(cell).append(button);
            cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="iaas_list_enroll"]');
            button  = $('<button>', { text : 'Enroll', id : 'enroll-iaas' })
                              .button({ icons : { primary : 'ui-icon-refresh' } })
                              .attr('style', 'margin-top:0;')
                              .click(function() {
                                console.log({ nodes : rowelem.nodes });
                                  ajax('POST', '/api/serviceprovider', { nodes : rowelem.nodes });
                              });
            $(cell).append(button);
        },
        action_delete: {
            callback: function (id) {
                var url = '/api/openstack/';
                confirmDelete(url, id, ['iaas_list']);
            }
        },
    });
}
