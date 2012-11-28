require('modalform.js');

function poolips_addbutton_action(e) {
    var edit    = !(e instanceof Object);
    (new ModalForm({
        title       : 'Create a PoolIP',
        name        : 'poolip',
        id          : (edit) ? e : undefined,
        fields      : {
            poolip_name     : { label : 'Name' },
            poolip_addr     : { label : 'First address' },
            poolip_mask     : { label : 'Size' },
            poolip_netmask  : { label : 'Netmask' },
            poolip_gateway  : { label : 'Gateway' }
        },
        callback    : function() { $('#poolips_list').trigger('reloadGrid'); }
    })).start();
}

function poolips_list(cid) {
    create_grid({
        url                     : '/api/poolip',
        content_container_id    : cid,
        grid_id                 : 'poolips_list',
        colNames                : [ 'Id', 'Name', 'First address', 'Size', 'Netmask', 'Gateway' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'poolip_name', index : 'poolip_name' },
            { name : 'poolip_addr', index : 'poolip_addr' },
            { name : 'poolip_mask', index : 'poolip_mask' },
            { name : 'poolip_netmask', index : 'poolip_netmask' },
            { name : 'poolip_gateway', index : 'poolip_gateway' }
        ],
        details                 : {
            onSelectRow : poolips_addbutton_action
        }
    });
    var addButton   = $('<a>', { text : 'Add a PoolIP' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', poolips_addbutton_action);
}
