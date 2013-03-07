//require('kanopyaformwizard.js');

function poolip_addbutton_action(e) {
    (new KanopyaFormWizard({
        title      : 'Create a Pool IP',
        type       : 'poolip',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'poolip_name', 'poolip_first_addr', 'poolip_size', 'network_id' ]
    })).start();
}

function poolips_list(cid) {
    create_grid({
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
    var action_div=$('#' + cid).prevAll('.action_buttons'); 
    var addButton   = $('<a>', { text : 'Add a Pool IP' }).appendTo(action_div)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', poolip_addbutton_action);
}
