require('kanopyaformwizard.js');

function network_addbutton_action(e) {
    (new KanopyaFormWizard({
        title      : 'Create a Network',
        type       : 'network',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'network_name', 'network_addr', 'network_netmask', 'network_gateway' ],
        relations  : { 'poolips' : [ 'poolip_name', 'poolip_first_addr', 'poolip_size' ] }
    })).start();
}

function networks_list(cid) {
    create_grid({
        url                     : '/api/network',
        content_container_id    : cid,
        grid_id                 : 'networks_list',
        colNames                : [ 'Id', 'Name', 'Network Address', 'Netmask', 'Gateway' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'network_name',    index : 'network_name' },
            { name : 'network_addr',    index : 'network_addr' },
            { name : 'network_netmask', index : 'network_netmask' },
            { name : 'network_gateway', index : 'network_gateway' }
        ],
        details                 : {
            onSelectRow : network_addbutton_action
        }
    });
    var addButton   = $('<a>', { text : 'Add a Network' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', network_addbutton_action);
}
