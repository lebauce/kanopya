require('common/formatters.js');
require('modalform.js');

var g_host_manager_id = undefined;

function host_addbutton_action(e) {
    (new ModalForm({
        title   : 'Create a host',
        name    : 'host',
        fields  : {
            host_hostname       : { label : 'Hostname' },
            host_desc           : { label : 'Description', type : 'textarea' },
            host_core           : { label : 'Core Number' },
            host_ram            : { label : 'RAM Amount' },
            kernel_id           : { label : 'Default Kernel', display : 'kernel_name' },
            host_serial_number  : { label : 'Serial number' },
            host_manager_id     : { label : '', value : g_host_manager_id, type : 'hidden' }
        }
    })).start();
}

function hosts_list(cid, host_manager_id) {
    g_host_manager_id   = host_manager_id;
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
        ]
    });
    var host_addbutton  = $('<a>', { text : 'Add a host' }).appendTo('#' + cid)
                            .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(host_addbutton).bind('click', host_addbutton_action);
}
