require('modalform.js');
require('common/formatters.js');

function netapp_addbutton_action(e) {
    (new ModalForm({
        title       : 'Create a NetApp',
        name        : 'netapp',
        id          : (!(e instanceof Object)) ? e : undefined,
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
        colNames                : ['Id', 'Name', 'Description', 'Address', 'Login', 'State', 'Synchronize'],
        colModel                : [
            { name : 'pk', index : 'pk', key : true, hidden : true, sorttype : 'int' },
            { name : 'netapp_name', index : 'netapp_name' },
            { name : 'netapp_desc', index : 'netapp_desc' },
            { name : 'netapp_addr', index : 'netapp_addr' },
            { name : 'netapp_login', index : 'netapp_login' },
            { name : 'state', index : 'state', width : 40, align : 'center' },
            { name : 'synchronize', index : 'synchronize', width : 40, align : 'center', nodetails : true }
        ],
        details                 : { onSelectRow : netapp_addbutton_action },
        afterInsertRow          : function(grid, rowid, rowdata, rowelem) {
            $.ajax({
                url     : '/api/netapp/' + rowid + '/getState',
                type    : 'POST',
                success : function(data) {
                    $(grid).setGridParam({ autoencode : false });
                    $(grid).setCell(rowid, 'state', StateFormatter(data));
                    $(grid).setGridParam({ autoencode : true });
                }
            });
            var cell        = $(grid).find('tr#' + rowid).find('td[aria-describedby="netapp_list_synchronize"]');
            var syncButton  = $('<div>').button({ text : false, icons : { primary : 'ui-icon-refresh' } }).appendTo(cell);
            $(syncButton).attr('style', 'margin-top:0px;');
            $(syncButton).click(function() {
                $.ajax({
                    url     : '/api/netapp/' + rowid + '/synchronize',
                    type    : 'POST'
                });
            });
        }
    });
    var action_div=$('#' + cid).prevAll('.action_buttons'); 
    action_div.empty();
    var netapp_addbutton    = $('<a>', { text : 'Create a NetApp' }).appendTo(action_div)
                                .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(netapp_addbutton).bind('click', netapp_addbutton_action);
}
