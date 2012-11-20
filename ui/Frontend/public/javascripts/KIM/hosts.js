require('common/formatters.js');
require('kanopyaformwizard.js');

var g_host_manager_id = undefined;

function host_addbutton_action(e) {
    (new KanopyaFormWizard({
        title      : 'Create a host',
        type       : 'host',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'host_desc', 'host_core', 'host_ram', 'kernel_id', 'host_serial_number' ],
        relations  : { 'ifaces' : [ 'iface_name', 'iface_mac_addr', 'iface_pxe', 'netconf_ifaces' ] },
        rawattrdef : {
            'host_manager_id' : {
                'value' : g_host_manager_id
            },
            'active' : {
                'value' : 1
            }
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
