// KIM services
require('common/service_common.js');
require('common/model.js');
require('common/general.js');

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

var resources  = {};

function servicesListFilter(elem) {
    if (resources.hasOwnProperty(elem.pk)) {
        return false;
    } else {
        return true;
    }
}

function servicesList (container_id, elem_id) {
    resources  = {};
    var providers = getServiceProviders('HostManager');
    for (var provider in providers) {
        resources[providers[provider].pk] = true;
    }

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
                        var name = serv_template ? serv_template.service_name : 'Internal';
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

    function createAddServiceButton(cid, grid) {
        var button = $("<button>", { id : 'instantiate_service_button', text : 'Instantiate a service'}).button({
            icons   : { primary : 'ui-icon-plusthick' }
        });

        button.bind('click', function() {
            // Use the kanopyaformwizard for policies
            (new KanopyaFormWizard({
                title        : 'Instantiate a service',
                type         : 'cluster',
                reloadable   : true,
                hideDisabled : true,
                stepsAsTags  : true,
                displayed    : [ 'cluster_name', 'cluster_desc', 'user_id', 'service_template_id' ],
                rawattrdef   : {
                    cluster_name : {
                        label        : 'Service name',
                        type         : 'string',
                        pattern      : '^[a-zA-Z_0-9]+$',
                        is_mandatory : true,
                        is_editable  : true
                    },
                    cluster_desc : {
                        label        : 'Service description',
                        type         : 'text',
                        pattern      : '^.*$',
                        is_mandatory : false,
                        is_editable  : true
                    },
                    user_id : {
                        label        : 'Customer',
                        type         : 'relation',
                        relation     : 'single',
                        pattern      : "^[1-9][0-9]+$",
                        is_mandatory : true,
                        is_editable  : true
                    },
                    service_template_id : {
                        label        : 'Service type',
                        type         : 'relation',
                        relation     : 'single',
                        reload       : true,
                        pattern      : "^[1-9][0-9]+$",
                        welcome      : "Select a service type",
                        is_mandatory : true,
                        is_editable  : true
                    }
                },
                attrsCallback : function (resource, data, trigger) {
                    var attributes;

                    // Define the cluster relation hard coded here, to avoid a call
                    // to the cluster attributes for the relations only
                    var cluster_relations = {
                        user : {
                            resource : "user",
                            cond     : { "foreign.user_id" : "self.user_id" },
                            attrs    : { accessor : "single" }
                        },
                        service_template : {
                            resource : "servicetemplate",
                            cond     : { "foreign.service_template_id" : "self.service_template_id" },
                            attrs    : { accessor : "single" }
                        }
                    };

                    // If the service template defined, fill the from with the service template definition
                    if (data.service_template_id) {
                        var args = { params : data, trigger : trigger };
                        attributes = ajax('POST', '/api/servicetemplate/getServiceTemplateDef', args);

                        // Delete the service template fields other than policies ids
                        delete attributes.attributes['service_name'];
                        delete attributes.attributes['service_desc'];

                    } else {
                        attributes = { attributes : {}, relations : {} };
                    }
                    $.extend(true, attributes.relations, cluster_relations);

                    // Set steps
                    set_steps(attributes);

                    // Set the value if defined (at reload)
                    $.each([ 'cluster_name', 'cluster_desc', 'user_id', 'service_template_id' ], function (index, attr) {
                        if (data[attr] !== undefined) {
                            if (attributes.attributes[attr] === undefined) {
                                attributes.attributes[attr] = {};
                            }
                            attributes.attributes[attr].value = data[attr];
                        }
                    });
                    return attributes;
                },
                optionsCallback : function (name, value, relations) {
                    if (name === 'user_id') {
                        return ajax('GET', '/api/user?user_profiles.profile.profile_name=Customer');

                    } else {
                        return false;
                    }
                },
                callback : function (data) {
                    handleCreateOperation(data, grid);
                }
            })).start();
        });
        
        $('#' + cid).append(button);
    };
	
    createAddServiceButton(container_id, grid);
}

function loadServicesResources (container_id, elem_id) {
    var loadServicesResourcesGridId = 'service_resources_list_' + elem_id;
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
        url: '/api/node?service_provider_id=' + elem_id,
        content_container_id: container_id,
        grid_id: loadServicesResourcesGridId,
        grid_class: 'service_resources_list',
        rowNum : 25,
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            addResourceExtraData(grid, rowid, rowdata, rowelem, nodemetricrules, elem_id, '');

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
                url     : '/api/host/' + host_id,
                type    : 'GET',
                success : function(host) {
                    $(grid).setCell(rowid, 'admin_ip', host.admin_ip);
                }
            });
        
        },
        colNames: [ 'id', 'host id', 'State', 'Hostname', 'Core', 'Ram', 'IP Admin', 'Rules State' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'host_id', index: 'host_id', hidden: true},
            { name: 'node_state', index: 'node_state', width: 90, formatter: StateFormatter },
            { name: 'node_hostname', index: 'node_hostname', width: 200 },
            { name: 'host_core', index: 'host_core', width: 40 },
            { name: 'host_ram', index: 'host_ram' },
            { name: 'admin_ip', index: 'admin_ip' },
            { name: 'rulesstate', index: 'rulestate' }
        ],
        details : {
            tabs : [
                        { label : 'General', id : 'generalnodedetails', onLoad : nodedetailsaction },
                        { label : 'Network Interfaces', id : 'iface', onLoad : function(cid, eid) {node_ifaces_tab(cid, eid); } },
                        { label : 'Monitoring', id : 'resource_monitoring', onLoad : NodeIndicatorDetailsHistorical },
                        { label : 'Rules', id : 'rules', onLoad : function(cid, eid) { node_rules_tab(cid, eid, elem_id); } },
                    ],
            title : { from_column : 'node_hostname' }
        },
        action_delete: {url : '/api/node'},
    } );
}

function runScaleWorkflow(type, eid, spid) {
    var cont    = $('<div>');
    $('<label>', { text : type + ' amount : ', for : type }).appendTo(cont);
    var inp         = $('<input>', { id : type }).appendTo(cont);
    var unit_cont   = $('<span>').appendTo(cont);
    addFieldUnit({ unit : (type == 'Memory' ? 'byte' : 'core(s)') }, unit_cont, 'scale_amount_unit');

    $(cont).dialog({
        resizable       : false,
        modal           : true,
        close           : function() { $(this).remove(); },
        buttons         :[
            {id:'button-cancel',text:'Cancel',click: function() { $(this).dialog('close');}},
            {id:'button-ok',text:'Ok',click: function() {
                var amount  = $(inp).val();
                if (amount != null && amount !== "") {
                    amount = getRawValue(amount, 'scale_amount_unit');
                    $.ajax({
                        async       : false,
                        url         : '/api/serviceprovider/' + spid + '/service_provider_managers?' +
                                      'manager_category.parent.category_name=HostManager&expand=manager_category',
                        type        : 'GET',
                        success     : function(hmgr) {
                            $.ajax({
                                url         : '/api/entity/' + hmgr[0].manager_id + '/scaleHost',
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
            }}
        ]
    });
}

function migrate(spid, eid) {
    var cont    = $('<div>');
    $('<label>', { text : 'Hypervisor : ', for : 'hypervisorselector' }).appendTo(cont);
    var sel     = $('<select>').appendTo(cont);
    $.ajax({
        async       : false,
        url         : '/api/serviceprovider/' + spid + '/service_provider_managers?' +
                      'manager_category.parent.category_name=HostManager&expand=manager_category',
        type        : 'GET',
        success     : function(hmgr) {
            $.ajax({
                url     : '/api/virtualization/' + hmgr[0].manager_id + '/hypervisors',
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
                                        url         : '/api/virtualization/' + hmgr[0].manager_id + '/migrate',
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
            var remoteUrl   = data.host.remote_session_url;
            var isActive    = data.host.active;
            var isUp        = (/^up:/).test(data.host.host_state);
            var isVirtual   = false;
            $.ajax({    
                url     : '/api/component/' + data.host.host_manager_id,
                type    : 'GET',
                async   : false,
                success : function(ret) {
                    if (ret.host_type === 'Virtual Machine') isVirtual = true;
                }
            });
            var buttons   = [
                {
                    label   : 'Stop node',
                    sprite  : 'stop',
                    action  : '/api/serviceprovider/' + data.service_provider_id + '/removeNode',
                    data    : { host_id : data.host.pk },
                    confirm : 'The node will be halted'
                },
                {
                    label   : 'Resubmit node',
                    sprite  : 'refresh',
                    condition : isVirtual,
                    action  : '/api/host/' + data.host.pk + '/resubmit',
                    confirm : 'The node will be stopped and restarted'
                },
                {
                    label       : 'Scale Cpu',
                    sprite      : 'scale',
                    condition   : isVirtual,
                    action      : function() { runScaleWorkflow("CPU", data.host.pk, data.service_provider_id); }
                },
                {
                    label       : 'Scale Memory',
                    sprite      : 'scale',
                    condition   : isVirtual,
                    action      : function() { runScaleWorkflow("Memory", data.host.pk, data.service_provider_id); }
                },
                {
                    label       : 'Migrate',
                    sprite      : 'migrate',
                    condition   : isVirtual,
                    action      : function() { migrate(data.service_provider_id, data.host.pk); }
                },
                {
                    label       : 'Remote session',
                    sprite      : 'scale',
                    condition   : (remoteUrl !== null && remoteUrl !== ''),
                    action      : function() { window.open(remoteUrl); }
                },
                {
                    label       : 'Put node in maintenance',
                    icon        : 'wrench',
                    condition   : !isVirtual && isUp && isActive,
                    action      : '/api/host/' + data.host.pk + '/maintenance',
                    confirm     : 'All the virtual machines will be migrated and the hypervisor will be put in maintenance'
                },
                {
                    label       : 'Restore from maintenance',
                    icon        : 'gear',
                    condition   : !isVirtual && isUp && !isActive,
                    action      : '/api/host/' + data.host.pk + '/restore',
                    confirm     : 'hypervisor will be now used to host virtual machines'
                },
            ]
            require('KIM/services_details.js');
            var action_div=$('#' + cid).prevAll('.action_buttons');
            createallbuttons(buttons, action_div);
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
