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
                        is_mandatory : true,
                        is_editable  : true
                    },
                    slave_ifaces : {
                        label        : 'Salve interfaces',
                        type         : 'relation',
                        relation     : 'multi',
                        link_to      : 'iface',
                        is_mandatory : false,
                        is_editable  : true,
                        reload_options : true
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
            return { attributes : attributes, relations : relations };
        },
        optionsCallback  : function (name, value, relations) {
            if (name === 'slave_ifaces') {
                // Find the input corresponding to defined ifaces,
                // and build an options list with.
                var options = [];
                this.form.find('#input_iface_name').each(function() {
                    if ($(this).val() != "") {
                        options.push({ label : $(this).val(), pk : $(this).val() });
                    }
                });
                return options;

            } else {
                return false;
            }
        },
        valuesCallback  : function(type, id, attributes) {
            var host = ajax('GET', '/api/' + type + '/' + id + '?expand=ifaces');

            var ifaces = host['ifaces'];
            host['ifaces'] = [];

            var bonding_ifaces = {};
            for (var index in ifaces) {
                var iface = ifaces[index];
                if (iface.master != undefined && iface.master !== "") {
                    if (bonding_ifaces[iface.master] === undefined) {
                        bonding_ifaces[iface.master] = [];
                    }
                    bonding_ifaces[iface.master].push(iface.iface_name);
                }
            }
            for (var index in ifaces) {
                var iface = ifaces[index];
                if (bonding_ifaces[iface.iface_name] === undefined) {
                    host['ifaces'].push(iface);
                }
            }

            host['bonding_ifaces'] = [];
            for (var bonding_iface_name in bonding_ifaces) {
                host['bonding_ifaces'].push({
                    bonding_iface_name : bonding_iface_name,
                    slave_iface : bonding_ifaces[bonding_iface_name]
                });
            }

            return host;
        },
        submitCallback  : function(data, $form, opts, onsuccess, onerror) {
            for (var bonding_index in data['bonding_ifaces']) {
                var bonding_iface = data['bonding_ifaces'][bonding_index];

                var netconfs = undefined;
                for (iface_index in data['ifaces']) {
                    var iface = data['ifaces'][iface_index];
                    if ($.inArray(iface.iface_name, bonding_iface.slave_ifaces) >= 0) {

                        var iface_netconfs = iface.netconf_ifaces;
                        if (netconfs === undefined) {
                            netconfs = iface_netconfs;

                        } else {
                            // TODO: check if ifaces netconfs match exactly to the
                            //       first slave iface found netconfs.
                        }
                        delete iface.netconf_ifaces;
                        iface.master = bonding_iface.bonding_iface_name;
                    }
                }

                data['ifaces'].push({
                    iface_name     : bonding_iface.bonding_iface_name,
                    iface_pxe      : 0,
                    netconf_ifaces : netconfs
                })
            }
            delete data['bonding_ifaces'];

            return ajax($(this.form).attr('method').toUpperCase(),
                        $(this.form).attr('action'), data, onsuccess, onerror);
        }
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
