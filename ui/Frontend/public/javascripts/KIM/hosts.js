require('common/formatters.js');

function host_addbutton_action(e) {
}

function hosts_list(cid) {
    create_grid({
        content_container_id    : cid,
        grid_id                 : 'hosts_list',
        url                     : '/api/host',
        colNames                : [ 'Id', 'Hostname', 'IP', 'Active', 'State' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'host_hostname', index : 'host_hostname' },
            { name : 'node.
            { name : 'active', index : 'active', formatter : function(a) { if (a) { return 'Enabled'; } else { return 'Disabled'; } } },
            { name : 'host_state', index : 'host_state', width : 40, align : 'center', formatter : StateFormatter }
        ]
    });
    var host_addbutton  = $('<a>', { text : 'Add a host' }).appendTo('#' + cid)
                            .button({ icons : { primary : 'ui-icon-plusthick' } });
}
