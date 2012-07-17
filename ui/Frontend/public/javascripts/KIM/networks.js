
function networks_addbutton_action() {
    (new ModalForm({
        title           : 'Create a Network',
        name            : 'network',
        fields          : {
            network_name    : { label : 'Name' },
            vlan_number     : { label : 'Vlan Number', skip : true }
        },
        beforeSubmit    : function(fdata, f, opts, mdfrm) {
            var vlannumber  = $(mdfrm.content).find(':input#input_vlan_number').val();
            if (vlannumber != null && vlannumber != "") {
                $(mdfrm.form).attr('action', '/api/vlan');
                fdata.push({
                    name    : 'vlan_number',
                    value   : vlannumber
                });
                opts.url    = '/api/vlan';
            }
            return true;
        },
        callback        : function() { $('#networks_list').trigger('reloadGrid'); }
    })).start();
}

function networks_list(cid) {
    create_grid({
        url                     : '/api/network',
        content_container_id    : cid,
        grid_id                 : 'networks_list',
        colNames                : [ 'Id', 'Name' ],
        colModel                : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'network_name', index : 'network_name' }
        ]
    });
    var addButton   = $('<a>', { text : 'Add a Network' }).appendTo('#' + cid)
                        .button({ icons : { primary : 'ui-icon-plusthick' } });
    $(addButton).bind('click', networks_addbutton_action);
}
