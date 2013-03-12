//require('kanopyaformwizard.js');
require('common/general.js');

function poolip_addbutton_action(e, grid) {
    (new KanopyaFormWizard({
        title      : 'Create a Pool IP',
        type       : 'poolip',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'poolip_name', 'poolip_first_addr', 'poolip_size', 'network_id' ],
        callback   : function () { handleCreate(grid); }
    })).start();
}

function poolips_list(cid) {
    var grid = create_grid({
        url                     : '/api/poolip',
        content_container_id    : cid,
        grid_id                 : 'poolips_list',
        colNames                : [ 'Id', 'Name', 'First address', 'Size' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'poolip_name', index : 'poolip_name' },
            { name : 'poolip_first_addr', index : 'poolip_first_addr' },
            { name : 'poolip_size', index : 'poolip_size' }
        ],
        details                 : {
            onSelectRow : poolip_addbutton_action
        }
    });
    var addButton   = $('<a>', { text : 'Add a Pool IP' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', function (e) {
        poolip_addbutton_action(e, grid);
    });
}
