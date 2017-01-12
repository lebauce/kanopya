require('common/formatters.js');
require('common/general.js');
require('KIM/services.js');
require('common/lib_list.js');

function hosts_list(containerId, hostManagerId) {

    var hostCollection;
    var isRunning = false;
    var hostManagerType;

    loadHostCollection();

    function loadHostCollection() {

        var hostObject;
        var index, value;

        hostCollection = [];

        $.getJSON(
            '/api/host?expand=node&host_manager_id=' + hostManagerId, function(data) {
            $.each(data, function(i, obj) {
                hostObject = createHostObject(obj);
                hostCollection.push(hostObject);
            });
            loadHostManagerType();
        });
    }

    function loadHostManagerType() {

        var componentTypeCategory;
        var i;

        hostManagerType = 'physical';

        $.getJSON(
            '/api/component/' + hostManagerId + '?expand=component_type.component_type_categories.component_category', function(data) {
            if (data.component_type && data.component_type.component_type_categories) {
                for (i = 0; i < data.component_type.component_type_categories.length; i++) {
                    componentTypeCategory = data.component_type.component_type_categories[i];
                    if (componentTypeCategory.component_category && componentTypeCategory.component_category.category_name === 'VirtualMachineManager') {
                        hostManagerType = 'virtual';
                        break;
                    }
                }
            }
            renderHtml();
        });
    }

    function createHostObject(obj) {

        var state, map;

        var stateMap = {
            'up'       : {
                'label': 'Up',
                'icon' : 'fa-check '
            },
            'in'       : {
                'label': 'Up',
                'icon' : 'fa-check '
            },
            'down'     : {
                'label': 'Down',
                'icon' : 'fa-times'
            },
            'broken'   : {
                'label': 'Broken',
                'icon' : 'fa-times'
            },
            'off'      : {
                'label': 'Inactive',
                'icon' : 'fa-power-off'
            }
        };

        var hostObject = {
            'id'               : obj.pk,
            'name'             : '',
            'description'      : obj.host_desc,
            'adminIp'          : obj.admin_ip,
            'serviceProviderId': null,
            'cpu'              : obj.host_core,
            'ramUnit'          : 'MB',
            'ram'              : obj.host_ram,
            'active'           : obj.active,
            'activeIcon'       : '',
            'state'            : obj.host_state,
            'hostCanStop'      : false,
            'hostCanScale'     : false,
            'hostCanActivate'  : false,
            'hostCanDeactivate': false,
            'hostCanRemove'    : false
        };

        if (obj.node) {
            hostObject.name = obj.node.node_hostname;
            hostObject.serviceProviderId = obj.node.service_provider_id;
        }

        index = hostObject.state.indexOf(':');
        if (index > -1) {
            hostObject.state = hostObject.state.substring(0, index);
        }
        if (!hostObject.state && hostObject.active != undefined && hostObject.active == '0') {
            hostObject.state = 'off';
        }
        if (hostObject.state in stateMap) {
            state = stateMap[hostObject.state];
            hostObject.stateLabel = state.label;
            hostObject.stateIcon = state.icon;
            hostObject.hostCanStop = (hostObject.serviceProviderId);
            hostObject.hostCanScale = (hostObject.serviceProviderId && hostManagerType === 'virtual');
            hostObject.hostCanScale = true;
        }

        if (!isNaN(hostObject.ram) && hostObject.ram > 0) {
            map = getReadableSize(hostObject.ram, false);
            hostObject.ramUnit = map.unit;
            hostObject.ram = map.value;
            hostObject.ram = formatMemory(hostObject.ram);
        }

        if (hostObject.active === undefined) {
            hostObject.hostCanRemove = true;
        } else {
            if (hostObject.active === '1') {
                hostObject.hostCanDeactivate = true;
            } else {
                hostObject.hostCanActivate = true;
            }
        }

        return hostObject;
    }

    function formatMemory(value) {

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

        clearHtml();
        createAddButton(containerId);
        renderTemplate();
    }

    function clearHtml() {

        var $elt = $('#host-home');
        if ($elt.length > 0) {
            $elt.remove();
        }
    }

    function createAddButton() {

        if ($('#host-add-button').length) {
            return;
        }

        var addButton  = $('<a>', {id: 'host-add-button', text: 'Add a host'})
            .button({icons: {primary: 'ui-icon-plusthick'}});

        var actionDiv = $('#' + containerId).prevAll('.action_buttons');
        actionDiv.append(addButton);

        $(addButton).bind('click', function (e) {
            host_addbutton_action(null);
        });
    }

    function renderTemplate() {

        var i;
        var templateFile = '/templates/host-home.tmpl.html';

        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('#' + containerId).append(template({
                'hostCollection': hostCollection
            }));
            activateEvents();
        });
    }

    function activateEvents() {

        activateExpander();

        // Detail
        $('.list-item-info .identifier span').click(function() {
            $(this)
                .parents('.list-item')
                .find('.button-detail')
                .trigger('click');
        });
        $('.button-detail').click(function() {
            var id = $(this).parent().data('id');
            host_addbutton_action(id);
        });

        // Stop
        $('.button-stop').click(function() {
            stopHost(this);
        });

        // Scale CPU
        $('.button-scale-cpu').click(function() {
            scaleHost('CPU', this);
        });

        // Scale RAM
        $('.button-scale-ram').click(function() {
            scaleHost('Memory', this);
        });

        // Activate host
        $('.button-activate').click(function() {
            activateHost(true, this);
        });

        // Deactivate host
        $('.button-deactivate').click(function() {
            activateHost(false, this);
        });

        $(document).on("kanopiaformwizardLoaded", function(event) {
            $('*').removeClass('cursor-wait');
        });
    }

    function getHostObjectById(id) {

        var hostObject = {};

        for (var i = 0; i < hostCollection.length; i++) {
            if (hostCollection[i].id == id) {
                hostObject = hostCollection[i];
                break;
            }
        }

        return hostObject;
    }

    function stopHost(element) {

        var id = $(element).parent().data('id');
        var hostObject = getHostObjectById(id);

        executeAction(
            '/api/serviceprovider/' + hostObject.serviceProviderId + '/removeNode',
            {node_id: hostObject.id},
            element,
            'The host will be halted.\nDo you want to continue?'
        );
    }

    function scaleHost(scaleType, element) {

        var id = $(element).parent().data('id');
        var hostObject = getHostObjectById(id);

        // function from services.js
        runScaleWorkflow(scaleType, id, hostObject.serviceProviderId, refreshItem);
    }

    function activateHost(toActivate, element) {

        var id = $(element).parent().data('id');
        var action = (toActivate === true) ? 'activate' : 'deactivate';
        var url = '/api/host/' + id + '/' + action;

        executeAction(
            url,
            '',
            element,
            'Do you want to ' + action + ' the host?'
        );
    }

    function executeAction(url, data, element, confirmationMessage) {

        if (isRunning === true) {
            return;
        }

       if (confirmationMessage) {
           if (confirm(confirmationMessage) === false) {
                return false;
            }
       }

        isRunning = true;

        var id = $(element).parent().data('id');
        startTextButtonAnimation(element);
        $.ajax({
            type: "POST",
            url: url,
            data: data,
            success: function() {
                refreshItem(id);
            },
            complete: function() {
                stopTextButtonAnimation(element);
                isRunning = false;
            }
        });
    }

    function refreshItem(id) {

        $.getJSON(
            '/api/host/' + id + '?expand=node',
            function(data) {
                var hostObject = createHostObject(data);
                var $item = $('#list-item' + id);
                var $elt, $child;

                $item.children('.list-item-box').attr('class', 'list-item-box ' + hostObject.state);

                $elt = $item.find('.state');
                $elt.children('.fa').attr('class', 'fa ' + hostObject.stateIcon);
                $elt.children('.label').text(hostObject.stateLabel);

                $item
                    .find('.cpu')
                    .children('.value')
                    .html(hostObject.cpu + '<span class="label">cores</span>');

                $item
                    .find('.ram')
                    .children('.value')
                    .html(hostObject.ram + '<span class="label">' + hostObject.ramUnit + '</span>');

                $elt = $item.children('.panel');
                $elt.attr('class', 'panel ' + hostObject.state);

                $elt = $elt.children('.button-group');

                $child = $elt.children('.button-stop');
                if (hostObject.hostCanStop) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action3 button-text button-stop">Stop</button>');

                            $elt.children('.button-stop').click(function() {
                                stopHost(this);
                            });
                    }
                } else if ($child.length) {
                    $child.remove();
                }

                $child = $elt.children('.button-activate');
                if (hostObject.hostCanActivate) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action4 button-text button-activate">Activate</button>');

                            $elt.children('.button-activate').click(function() {
                                activateHost(true, this);
                            });
                    }
                } else if ($child.length) {
                    $child.remove();
                }

                $child = $elt.children('.button-deactivate');
                if (hostObject.hostCanDeactivate) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action5 button-text button-deactivate">Deactivate</button>');

                            $elt.children('.button-deactivate').click(function() {
                                activateHost(false, this);
                            });
                    }
                } else if ($child.length) {
                    $child.remove();
                }

                $child = $elt.children('.button-scale-cpu');
                if (hostObject.hostCanScale) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action2 button-text button-scale-cpu">Scale CPU</button>');

                            $elt.children('.button-scale-cpu').click(function() {
                                scaleHost('CPU', this);
                            });
                    }
                } else if ($child.length) {
                    $child.remove();
                }

                $child = $elt.children('.button-scale-ram');
                if (hostObject.hostCanScale) {
                    if ($child.length === 0) {
                        $elt.prepend('<button type="button" class="btn btn-action2 button-text button-scale-ram">Scale RAM</button>');

                            $elt.children('.button-scale-ram').click(function() {
                                scaleHost('Memory', this);
                            });
                    }
                } else if ($child.length) {
                    $child.remove();
                }
            }
        );
    }

    function host_addbutton_action(hostId) {

        $('*').addClass('cursor-wait');
        // Delay to display the wait cursor
        setTimeout(function() {
            openEditor(hostId);
        }, 20);
    }

    function openEditor(hostId) {

        var rawattrdef = {
            host_manager_id : {
                value : hostManagerId,
                // Required to avoid the field disabled
                is_editable : 1
            }
        };

        if (hostId === null) {
            rawattrdef['active'] = {
                value : 1,
                // Required to avoid the field disabled
                is_editable : 1
            };
        }

        (new KanopyaFormWizard({
            title      : (hostId === null) ? 'Create a host' : 'Edit a host',
            type       : 'host',
            id         : (hostId !== null) ? hostId : undefined,
            displayed  : [ 'host_desc', 'host_core', 'host_ram', 'kernel_id', 'host_serial_number', 'entity_tags' ],
            relations  : { 'ifaces'         : [ 'iface_name', 'iface_mac_addr', 'iface_pxe', 'netconf_ifaces' ],
                           'bonding_ifaces' : [ 'bonding_iface_name', 'slave_ifaces' ],
                           'harddisks'      : [ 'harddisk_device', 'harddisk_size' ],
                           'ipmi_credentials'      : [ 'ipmi_credentials_ip_addr', 'ipmi_credentials_user', 'ipmi_credentials_password' ] },
            rawattrdef : rawattrdef,
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
                            label        : 'Slave interfaces',
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
                    this.form.find('input[name="iface_name"]').each(function() {
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
                var host = ajax('GET', '/api/' + type + '/' + id + '?expand=ifaces,ifaces.netconf_ifaces,harddisks,ipmi_credentials,entity_tags');
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
                    var netconfs = iface['netconf_ifaces'];
                    iface['netconf_ifaces'] = [];
                    for (var netconf in netconfs) {
                        iface['netconf_ifaces'].push(netconfs[netconf].netconf_id);
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
                        slave_ifaces : bonding_ifaces[bonding_iface_name]
                    });
                }

                host['entity_tags'] = $.map(host['entity_tags'], function(e) {return e.tag_id});

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
            },
            callback : function (data) {
                if (hostId) {
                    refreshItem(hostId);
                } else {
                    hosts_list(containerId, hostManagerId);
                }
            }
        })).start();
    }

    return;
    ////////////////////////////////////////////////////////////////////

    g_host_manager_id = hostManagerId;

    var grid = create_grid({
        content_container_id    : containerId,
        grid_id                 : 'hosts_list',
        url                     : '/api/host?expand=node&host_manager_id=' + g_host_manager_id,
        colNames                : [ 'Id', 'Hostname', 'Description', 'Active', 'State' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'node.node_hostname', index : 'node.node_hostname' },
            { name : 'host_desc', index : 'host_desc' },
            { name : 'active', index : 'active', width : 40, align : 'center', formatter : function(cell, formatopts, row) { return booleantostateformatter(cell, 'active', 'inactive') } },
            { name : 'host_state', index : 'host_state', width : 40, align : 'center', formatter : StateFormatter }
        ],
        details                 : { onSelectRow : host_addbutton_action },
        deactivate              : true
    });
    /*var host_addbutton  = $('<a>', { text : 'Add a host' }).appendTo('#' + containerId)
                            .button({ icons : { primary : 'ui-icon-plusthick' } });*/
    var action_div=$('#' + containerId).prevAll('.action_buttons');
    var host_addbutton  = $('<a>', { text : 'Add a host' }).appendTo(action_div)
                            .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(host_addbutton).bind('click', function (e) {
        host_addbutton_action(e, grid);
    });
}
