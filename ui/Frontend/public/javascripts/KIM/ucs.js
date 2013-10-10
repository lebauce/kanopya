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

function service_profiles(cid, eid, template) {
    $.ajax({
        url     : '/api/ucsmanager?service_provider_id=' + eid,
        success : function(data) {
            var ucsmanager  = data[0];
            $.ajax({
                url     : '/api/ucsmanager/' + ucsmanager.pk + ((template) ? '/get_service_profile_templates' : '/get_service_profiles'),
                type    : 'POST',
                success : function(data) {
                    create_grid({
                        content_container_id    : cid,
                        grid_id                 : 'service_profile_templates_list',
                        data                    : data,
                        colNames                : ['Name', 'DN'],
                        colModel                : [
                            { name : 'name', index : 'name' },
                            { name : 'dn', index : 'dn' }
                        ],
                        action_delete           : 'no'
                    });
                }
            });
        }
    });
}

function blades(cid, eid) {
    $.ajax({
        url     : '/api/ucsmanager?service_provider_id=' + eid,
        success : function(data) {
            var ucsmanager  = data[0];
            $.ajax({
                url     : '/api/ucsmanager/' + ucsmanager.pk + '/get_blades',
                type    : 'POST',
                success : function(data) {
                    create_grid({
                        content_container_id    : cid,
                        grid_id                 : 'service_profile_templates_list',
                        data                    : data,
                        colNames                : ['Model'],
                        colModel                : [
                            { name : 'model', index : 'model' }
                        ],
                        action_delete           : 'no'
                    });
                }
            });
        }
    });
}

function ucs_list(cid) {
    create_grid({
        content_container_id    : cid,
        grid_id                 : 'ucs_list',
        url                     : '/api/unifiedcomputingsystem',
        colNames                : ['Id', 'Name', 'Description', 'Address', 'Login', 'OU', 'State', ''],
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
        details                 : { tabs : [
            { label : 'Service Profiles Templates', id : 'service_profiles_templates', onLoad : function(cid, eid) { service_profiles(cid, eid, true); } },
            { label : 'Service Profiles', id : 'service_profiles', onLoad : function(cid, eid) { service_profiles(cid, eid, false); } },
            { label : 'Blades', id : 'blades', onLoad : blades }
        ] },
        afterInsertRow          : function(grid, rowid, rowdata, rowelem) {
            var cell    = $(grid).find('tr#' + rowid).find('td[aria-describedby="ucs_list_synchronize"]');
            var button  = $('<button>', { text : 'Sync',id:'sync-ucs' }).button({ icons : { primary : 'ui-icon-refresh' } })
                                       .attr('style', 'margin-top:0;')
                                       .click(function() {
                                            $.ajax({
                                                url     : '/api/unifiedcomputingsystem/' + rowid + '/synchronize',
                                                type    : 'POST'
                                            });
                                       });
            $(cell).append(button);

            button      = $('<button>', { text : 'Edit',id:'edit-ucs' }).button({ icons : { primary : 'ui-icon-wrench' } })
                                       .attr('style', 'margin-top:0;')
                                       .click(function() { ucsaddbutton_action(rowid);  });
            $(cell).append(button);
        }
    });
    var action_div=$('#' + cid).prevAll('.action_buttons'); 
    $('<a>', { text : 'Add an UCS' }).button({ icons : { primary : 'ui-icon-plusthick' } })
                                     .appendTo(action_div).bind('click', ucsaddbutton_action);
}
