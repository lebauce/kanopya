require('modalform.js');

function netapp_addbutton_action(e) {
    (new ModalForm({
        title       : 'Create a NetApp',
        name        : 'netapp',
        fields      : {
            netapp_name     : { label : 'Name' },
            netapp_desc     : { label : 'Description', type : 'textarea' },
            netapp_addr     : { label : 'Address' },
            netapp_login    : { label : 'Login' },
            netapp_passwd   : { label : 'Password', type : 'password' }
        },
        callback    : function() {
            $('#netapp_list').trigger('reloadGrid');
        }
    })).start();
}

function netapp_list(cid) {
    create_grid({
        content_container_id    : cid,
        url                     : '/api/netapp',
        grid_id                 : 'netapp_list',
        colNames                : ['Id', 'Name', 'Description'],
        colModel                : [
            { name : 'pk', index : 'pk', key : true, hidden : true, sorttype : 'int' },
            { name : 'netapp_name', index : 'netapp_name' },
            { name : 'netapp_desc', index : 'netapp_desc' }
        ]
    });
    
    var netapp_addbutton    = $('<a>', { text : 'Create a NetApp' }).appendTo('#' + cid)
                                .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(netapp_addbutton).bind('click', netapp_addbutton_action);
}
