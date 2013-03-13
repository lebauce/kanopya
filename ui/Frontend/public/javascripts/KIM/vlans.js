require('common/general.js');

function vlan_addbutton_action(e, grid) {
    (new KanopyaFormWizard({
        title      : 'Create a VLAN',
        type       : 'vlan',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'vlan_name', 'vlan_number' ],
        callback   : function (data) { handleCreate(grid); }
    })).start();
}

function vlans_list(cid) {
    var grid = create_grid({
        url                     : '/api/vlan',
        content_container_id    : cid,
        grid_id                 : 'vlans_list',
        colNames                : [ 'Id', 'Name', 'Number' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'vlan_name', index : 'vlan_name' },
            { name : 'vlan_number', index : 'vlan_number' }
        ],
         details                 : {
            onSelectRow : vlan_addbutton_action
        }
    });
    var action_div=$('#' + cid).prevAll('.action_buttons'); 
    var addButton   = $('<a>', { text : 'Add a VLAN' }).appendTo(action_div)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', function (e) {
        vlan_addbutton_action(e, grid);
    });
}
