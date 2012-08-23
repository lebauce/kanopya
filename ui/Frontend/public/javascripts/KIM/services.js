// KIM services

require('modalform.js');
require('common/service_common.js');
require('common/model.js');

// Must progressively move functions in the Service class
var Service = (function(_super) {

    Service.prototype   = new _super();

    function Service(id) {
        _super.call(this, id, 'serviceprovider');
    }

    Service.prototype.getMonthlyConsommationCSV = function() {
        window.open('/consommation/cluster/' + this.id);
    };

    return Service;
})(Model);

var ressources  = {};

function    servicesListFilter(elem) {
    if (ressources.hasOwnProperty(elem.pk)) {
        return false;
    } else {
        return true;
    }
}

function servicesList (container_id, elem_id) {
    $.ajax({
        url         : '/api/serviceprovider/getServiceProviders',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ category : 'Cloudmanager' }),
        success     : function(data) {
            ressources  = {};
            for (var i in data) if (data.hasOwnProperty(i)) {
                if (data[i] != undefined) {
                    ressources[data[i].pk] = true;
                }
            }
        }
    });
    var container = $('#' + container_id);

    $('a[href=#content_services_overview_static]').text('Service instances');

    if($('#services_list') !=  undefined) {
        $('#services_list').jqGrid('GridDestroy');
    }

    var grid = create_grid( {
        url: '/api/cluster',
        content_container_id: container_id,
        grid_id: 'services_list',
        afterInsertRow: function (grid, rowid, rowdata, rowelem) {
            if (!servicesListFilter(rowelem)) {
                $(grid).jqGrid('delRowData', rowid);
            } else {
                addServiceExtraData(grid, rowid, rowdata, rowelem, '');

                // Service name
                $.ajax({
                    url     : '/api/cluster/' + rowid + '/service_template',
                    type    : 'GET',
                    success : function(serv_template) {
                        var name;
                        if (serv_template) name = serv_template.service_name;
                        else               name = 'Internal';

                        $(grid).setCell(rowid, 'service_template_name', name);
                    },
                });
            }
        },
        rowNum : 25,
        colNames: [ 'ID', 'Service', 'Instance Name', 'State', 'Rules State', 'Node Number' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: "int", hidden: true, key: true },
            { name: 'service_template_name', index: 'service_template_name', width: 200 },
            { name: 'cluster_name', index: 'service_name', width: 200 },
            { name: 'cluster_state', index: 'service_state', width: 90, formatter:StateFormatter },
            { name: 'rulesstate', index : 'rulesstate' },
            { name: 'node_number', index: 'node_number', width: 150 }
        ],
        elem_name   : 'service',
        details     : { link_to_menu : 'yes', label_key : 'cluster_name'}
    });
    
    //$("#services_list").on('gridChange', reloadServices);
    
    function createServiceDef () {
        var service_def = jQuery.extend(true, {}, service);

        for (var policy in policies) {
            var policy_def = jQuery.extend(true, {}, policies[policy]);

            var step = policy.substring(0, 1).toUpperCase() + policy.substring(1);

            // Add the policy selection input
            service_def[policy + '_policy_id'] = {
                label           : step + ' policy',
                step            : step,
                type            : 'select',
                entity          : 'policy',
                filters         : { policy_type : policy },
                display         : 'policy_name',
                values_provider : {
                    func : 'getFlattenedHash',
                    args : { },
                },
                is_mandatory    : true,
                pattern         : '^[1-9][0-9]*$',
                disable_filled  : true,
            };
            service_def.service_template_id.fields_provided.push(policy + '_policy_id');

            for (var field in policy_def) {
                if (field !== 'policy_name' && field !== 'policy_desc') {
                    policy_def[field].policy         = policy;
                    policy_def[field].step           = step;
                    policy_def[field].disable_filled = true;
                    policy_def[field].hide_filled    = true;

                    if (! policy_def[field].composite &&  policy_def[field].type != 'hidden') {
                        policy_def[field].is_mandatory   = true;
                    }

                    service_def[field] = policy_def[field];
                }
            }
        }
        return service_def;
    }

    function createAddServiceButton(cid, grid) {
        var service_opts = {
            title       : 'Instantiate a service',
            name        : 'cluster',
            callback    : function () { $(grid).trigger("reloadGrid"); }
        };

        var button = $("<button>", { id : 'instantiate_service_button', text : 'Instantiate a service'} ).button({
            icons   : { primary : 'ui-icon-plusthick' }
        });

        button.bind('click', function() {
            service_opts.fields = createServiceDef();
            new PolicyForm(service_opts).start();
        });

        $('#' + cid).append(button);
    };

    createAddServiceButton(container_id, grid);
}

function loadServicesRessources (container_id, elem_id) {
    var loadServicesRessourcesGridId = 'service_ressources_list_' + elem_id;
    var nodemetricrules;
    var container = $('#'+container_id);

    // Node indicator historical graph details handler
    function NodeIndicatorDetailsHistorical(cid, node_id) {
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_historical_node_indicator.html', function() {
          initNodeIndicatorWidget(cont, elem_id, node_id);
      });
    }

    $.ajax({
        url     : '/api/nodemetricrule?nodemetric_rule_service_provider_id=' + elem_id,
        success : function(data) {
            nodemetricrules   = data;
        }
    });
    create_grid( {
        url: '/api/node?inside_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesRessourcesGridId,
        grid_class: 'service_ressources_list',
        rowNum : 25,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            addRessourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, elem_id, '');

            // Core and ram info
            var host_id  = $(grid).getCell(rowid, 'host_id');
            $.ajax({
                url     : '/api/host/' + host_id,
                type    : 'GET',
                success : function(data) {
                    $(grid).setCell(rowid, 'host_core', data.host_core);
                    $(grid).setCell(rowid, 'host_ram', (data.host_ram / (1024*1024)) + 'MB');
                }
            });
            // admin ip 
            $.ajax({
                url     : '/api/host/' + host_id + '/getAdminIp',
                type    : 'POST',
                success : function(data) {
                    $(grid).setCell(rowid, 'admin_ip', data);
                }
            });
        
        },
        colNames: [ 'id', 'host id', 'State', 'Hostname', 'Core', 'Ram', 'IP Admin', 'Rules State' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'host_id', index: 'host_id', hidden: true},
            { name: 'node_state', index: 'node_state', width: 90, formatter: StateFormatter },
            { name: 'externalnode_hostname', index: 'node_hostname', width: 200 },
            { name: 'host_core', index: 'host_core', width: 40 },
            { name: 'host_ram', index: 'host_ram' },
            { name: 'admin_ip', index: 'admin_ip' },
            { name: 'rulesstate', index: 'rulestate' }
        ],
        details : {
            tabs : [
                        { label : 'General', id : 'generalnodedetails', onLoad : nodedetailsaction },
                        { label : 'Network Interfaces', id : 'iface', onLoad : function(cid, eid) {node_ifaces_tab(cid, eid); } },
                        { label : 'Monitoring', id : 'ressource_monitoring', onLoad : NodeIndicatorDetailsHistorical },
                        { label : 'Rules', id : 'rules', onLoad : function(cid, eid) { node_rules_tab(cid, eid, elem_id); } },
                    ],
            title : { from_column : 'externalnode_hostname' }
        },
        action_delete: {url : '/api/node'},
    } );
}

function runScaleWorkflow(type, eid, spid) {
    var cont    = $('<div>');
    $('<label>', { text : type + ' amount : ', for : type }).appendTo(cont);
    var inp     = $('<input>', { id : type }).appendTo(cont);
    $(cont).dialog({
        resizable       : false,
        modal           : true,
        close           : function() { $(this).remove(); },
        buttons         : {
            'Ok'        : function() {
                var amount  = $(inp).val();
                if (amount != null && amount !== "") {
                    $.ajax({
                        async       : false,
                        url         : '/api/serviceprovider/' + spid + '/getManager',
                        contentType : 'application/json',
                        type        : 'POST',
                        data        : JSON.stringify({ manager_type : 'host_manager' }),
                        success     : function(hmgr) {
                            $.ajax({
                                url         : '/api/entity/' + hmgr.pk + '/scaleHost',
                                type        : 'POST',
                                contentType : 'application/json', 
                                data        : JSON.stringify({  
                                    host_id         : eid,
                                    scalein_value   : amount,
                                    scalein_type    : type.toLowerCase()
                                }),
                                success     : function() { $(cont).dialog('close'); }
                            });
                        }
                    });
                }
            },
            'Cancel'    : function() { $(this).dialog('close'); }
        }
    });
}

function migrate(spid, eid) {
    var cont    = $('<div>');
    $('<label>', { text : 'Hypervisor : ', for : 'hypervisorselector' }).appendTo(cont);
    var sel     = $('<select>').appendTo(cont);
    $.ajax({
        async       : false,
        url         : '/api/serviceprovider/' + spid + '/getManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ manager_type : 'host_manager' }),
        success     : function(hmgr) {
            $.ajax({
                url     : '/api/opennebula3/' + hmgr.pk + '/getHypervisors',
                type    : 'POST',
                success : function(data) {
                    for (var i in data) if (data.hasOwnProperty(i)) {
                        $(sel).append($('<option>', { text : data[i].host_hostname, value : data[i].pk }));
                    }
                    $(cont).dialog({
                        modal       : true,
                        resizable   : false,
                        close       : function() { $(this).remove(); },
                        buttons     : {
                            'Ok'        : function() {
                                var hyp = $(sel).val();
                                if (hyp != null && hyp != "") {
                                    $.ajax({
                                        url         : '/api/opennebula3/' + hmgr.pk + '/migrate',
                                        type        : 'POST',
                                        contentType : 'application/json',
                                        data        : JSON.stringify({
                                            host_id         : eid,
                                            hypervisor_id   : hyp
                                        }),
                                        success     : function() {
                                            $(cont).dialog('close');
                                        }
                                    });
                                }
                            },
                            'Cancel'    : function() { $(this).dialog('close'); }
                        }
                    });
                }
            });
        }
    });
}

function nodedetailsaction(cid, eid) {
    if (eid.indexOf('_') !== -1) {
        eid = (eid.split('_'))[0];
    }
    $.ajax({
        url     : '/api/node/' + eid + '?expand=host',
        success : function(data) {
            var remoteUrl   = null;
            var isVirtual   = false;
            $.ajax({
                url         : '/api/host/' + data.host.pk + '/getRemoteSessionURL',
                type        : 'POST',
                async       : false,
                success     : function(ret) {
                    remoteUrl   = ret;
                }
            });
            $.ajax({    
                url     : '/api/host/' + data.host.pk + '/getHostType',
                type    : 'POST',
                async   : false,
                success : function(ret) {
                    if (ret === 'Virtual Machine') isVirtual = true;
                }
            });
            var buttons   = [
                {
                    label   : 'Stop node',
                    icon    : 'stop',
                    action  : '/api/serviceprovider/' + eid + '/removeNode',
                    data    : { host_id : data.host.pk }
                },
                {
                    label       : 'Scale Cpu',
                    icon        : 'arrowthick-2-n-s',
                    condition   : isVirtual,
                    action      : function() { runScaleWorkflow("CPU", data.host.pk, data.service_provider_id); }
                },
                {
                    label       : 'Scale Memory',
                    icon        : 'arrowthick-2-n-s',
                    condition   : isVirtual,
                    action      : function() { runScaleWorkflow("Memory", data.host.pk, data.service_provider_id); }
                },
                {
                    label       : 'Migrate',
                    icon        : 'extlink',
                    condition   : isVirtual,
                    action      : function() { migrate(data.service_provider_id, data.host.pk); }
                },
                {
                    label       : 'Remote session',
                    icon        : 'image',
                    condition   : (remoteUrl !== null && remoteUrl !== ''),
                    action      : function() { window.open(remoteUrl); }
                }
            ]
            require('KIM/services_details.js');
            createallbuttons(buttons, $('#' + cid));
        }
    });
}

// load network interfaces details grid for a node
function node_ifaces_tab(cid, eid) {
    var node;
    $.ajax({
        url     : '/api/node?node_id=' + eid,
        type    : 'GET',
        async   : false,
        success : function(data) {
            node = data[0];
        }
    });
    create_grid( {
        url: '/api/iface?host_id=' + node.host_id,
        content_container_id: cid,
        grid_id: 'node_ifaces_tab',
        grid_class: 'node_ifaces_tab',
        action_delete: 'no',
        colNames: [ 'id', 'name', 'MAC address','IP address', 'pxe enabled',  ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'iface_name', index: 'iface_name', width: 10,},
            { name: 'iface_mac_addr', index: 'iface_mac_addr', width: 10 },
            { name: 'iface_ip', index: 'iface_ip', width: 10 },
            { name: 'iface_pxe', index: 'iface_pxe', width: 10 },
        ],
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            // ip address
            var iface_id = $(grid).getCell(rowid, 'pk');
            $.ajax({
                url     : '/api/ip?iface_id=' + iface_id,
                type    : 'GET',
                success : function(data) {
                    if(data.length == 1) {
                        $(grid).setCell(rowid, 'iface_ip', data[0].ip_addr);
                    } else {
                        $(grid).setCell(rowid, 'iface_ip', 'none');
                    }
                }
            });
            if(rowdata.iface_pxe == '1') { 
                $(grid).setCell(rowid, 'iface_pxe', 'yes');
            } else {
                $(grid).setCell(rowid, 'iface_pxe', 'no');
            }
        },
    });
}
