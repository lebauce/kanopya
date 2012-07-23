require('common/formatters.js');

function ucsaddbutton_action(e) {
    (new ModalForm({
        title       : 'Add an UCS',
        name        : 'unifiedcomputingsystem',
        id          : (e instanceof Object) ? undefined : e,
        fields      : {
            ucs_name    : { label : 'Name' },
            ucs_desc    : { label : 'Description', type : 'textarea' },
            ucs_addr    : { label : 'Address' },
            ucs_login   : { label : 'Login' },
            ucs_passwd  : { label : 'Password', type : 'password' },
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
        colNames                : ['Id', 'Name', 'Description', 'Address', 'Login', 'OU', 'State', 'Synchronize'],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'ucs_name', index : 'ucs_name' },
            { name : 'ucs_desc', index : 'ucs_desc' },
            { name : 'ucs_addr', index : 'ucs_addr' },
            { name : 'ucs_login', index : 'ucs_login' },
            { name : 'ucs_ou', index : 'ucs_ou' },
            { name : 'ucs_state', index : 'ucs_state', width : 40, align : 'center', formatter : StateFormatter },
            { name : 'synchronize', index : 'synchronize', width : 40, align : 'center', nodetails : true }
        ],
        details                 : { onSelectRow : ucsaddbutton_action },
        afterInsertRow          : function(grid, rowid, rowdata, rowelem) {
            var cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="ucs_list_synchronize"]');
            var button  = $('<button>').button({ text : false, icons : { primary : 'ui-icon-refresh' } })
                                        .attr('style', 'margin-top:0;')
                                        .click(function() {
                                            $.ajax({
                                                url     : '/api/unifiedcomputingsystem/' + rowid + '/synchronize',
                                                type    : 'POST'
                                            });
                                        });
            $(cell).append(button);
        }
    });
    $('<a>', { text : 'Add an UCS' }).button({ icons : { primary : 'ui-icon-plusthick' } })
                                    .appendTo('#' + cid).bind('click', ucsaddbutton_action);
}
