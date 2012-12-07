//require('kanopyaformwizard.js');

function netconf_addbutton_action(e) {
    (new KanopyaFormWizard({
        title      : 'Create a Network Configuration',
        type       : 'netconf',
        id         : (!(e instanceof Object)) ? e : undefined,
        displayed  : [ 'netconf_name', 'netconf_vlans', 'netconf_poolips', 'netconf_role_id' ]
    })).start();
}

function netconfs_list(cid) {
    create_grid({
        url                     : '/api/netconf',
        content_container_id    : cid,
        grid_id                 : 'netconfs_list',
        colNames                : [ 'Id', 'Name' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'netconf_name', index : 'netconf_name' }
        ],
        details                 : {
            onSelectRow : netconf_addbutton_action
        }
    });
    var addButton   = $('<a>', { text : 'Add a Network Configuration' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', netconf_addbutton_action);
}
