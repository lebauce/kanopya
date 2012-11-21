require('common/formatters.js');
require('kanopyaformwizard.js');

var g_host_manager_id = undefined;

function host_addbutton_action(e) {
    (new KanopyaFormWizard({
        title      : 'Create a host',
        type       : 'host',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'host_desc', 'host_core', 'host_ram', 'kernel_id', 'host_serial_number' ],
        relations  : { 'ifaces'         : [ 'iface_name', 'iface_mac_addr', 'iface_pxe', 'netconf_ifaces' ],
                       'bonding_ifaces' : [ 'bonding_iface_name', 'slave_ifaces' ] },
        rawattrdef : {
            'host_manager_id' : {
                'value' : g_host_manager_id
            },
            'active' : {
                'value' : 1
            }
        },
        attrsCallback  : function (resource) {
            var attributes;
            var relations;

            if (resource === 'host') {
                // If ressource is the host, add the fake relation bonding_ifaces
                var response = ajax('GET', '/api/attributes/' + resource);
                response.attributes['bonding_ifaces'] = {
                    label       : 'Bonding interfaces',
                    type        : 'relation',
                    relation    : 'single_multi',
                    is_editable : true
                };
                response.relations['bonding_ifaces'] = {
                    attrs : {
                        accessor : 'multi'
                    },
                    cond : {
                        'foreign.bonding_ifaces_id' : 'self.bonding_ifaces_id'
                    },
                    resource: 'bonding_ifaces'
                };
                return response;

            } else if (resource === 'bonding_ifaces') {
                attributes = {
                    bonding_ifaces_id : {
                        is_primary   : true,
                        is_mandatory : false
                    },
                    bonding_iface_name : {
                        label        : 'Bonding interface name',
                        type         : 'string',
                        is_mandatory : true
                    },
                    slave_ifaces : {
                        label        : 'Salve interfaces',
                        type         : 'relation',
                        relation     : 'mutli',
                        link_to      : 'iface',
                        is_mandatory : false,
                        is_editable  : true
                    }
                };
                relations = {
                    slave_ifaces : {
                        attrs : {
                            accessor : 'multi'
                        },
                        cond : {
                            'foreign.iface_id' : 'self.iface_id'
                        },
                        resource: 'iface'
                    }
                };

            } else {
                return ajax('GET', '/api/attributes/' + resource);
            }
            return { attributes : attributes, relations : {} };
        },
        valuesCallback : undefined,
        submitCallback : undefined
    })).start();
}

function hosts_list(cid, host_manager_id) {
    g_host_manager_id = host_manager_id;
    create_grid({
        content_container_id    : cid,
        grid_id                 : 'hosts_list',
        url                     : '/api/host?host_manager_id=' + g_host_manager_id,
        colNames                : [ 'Id', 'Hostname', 'Description', 'Active', 'State' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'host_hostname', index : 'host_hostname' },
            { name : 'host_desc', index : 'host_desc' },
            { name : 'active', index : 'active', width : 40, align : 'center', formatter : booleantostateformatter },
            { name : 'host_state', index : 'host_state', width : 40, align : 'center', formatter : StateFormatter }
        ],
        details                 : { onSelectRow : host_addbutton_action }
    });
    var host_addbutton  = $('<a>', { text : 'Add a host' }).appendTo('#' + cid)
                            .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(host_addbutton).bind('click', host_addbutton_action);
}
