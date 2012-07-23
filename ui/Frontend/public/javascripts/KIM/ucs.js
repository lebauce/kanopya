require('common/formatters.js');

function ucsaddbutton_action(e) {
    (new ModalForm({
        title       : 'Add an UCS',
        name        : 'unifiedcomputingsystem',
        fields      : {
            ucs_name    : { label : 'Name' },
            ucs_desc    : { label : 'Description', type : 'textarea' },
            ucs_addr    : { label : 'Address' },
            ucs_login   : { label : 'Login' },
            ucs_passwd  : { label : 'Password', type : 'passwd' },
            ucs_ou      : { label : 'OU' }
        },
        callback    : function() {
            $('#ucs_list').trigger('reloadGrid');
        }
    })).start();
}

function ucs_list(cid) {
    create_grid({
        content_container_id    : cid,
        grid_id                 : 'ucs_list',
        url                     : '/api/unifiedcomputingsystem',
        colNames                : ['Id', 'Name', 'Description', 'Address', 'Login', 'OU', 'State'],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'ucs_name', index : 'ucs_name' },
            { name : 'ucs_desc', index : 'ucs_desc' },
            { name : 'ucs_addr', index : 'ucs_addr' },
            { name : 'ucs_login', index : 'ucs_login' },
            { name : 'ucs_ou', index : 'ucs_ou' },
            { name : 'ucs_state', index : 'ucs_state', width : 40, align : 'center', formatter : StateFormatter }
        ]
    });
    $('<a>', { text : 'Add an UCS' }).button({ icons : { primary : 'ui-icon-plusthick' } })
                                    .appendTo('#' + cid).bind('click', ucsaddbutton_action);
}
