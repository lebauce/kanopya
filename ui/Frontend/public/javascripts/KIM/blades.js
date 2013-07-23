function add_hpc(id) {
    var kfw;
    kfw = new KanopyaFormWizard({
        title          : 'HP C7000',
        id             : (id instanceof Object) ? undefined : id,
        type           : 'hpcmanager',
        displayed      : [ 'bladesystem_ip', 'virtualconnect_ip' ],
        submitCallback : function(data, $form, opts, onsuccess, onerror) {
            var sp_id = $form.find('#input_service_provider_id').val();
            if (sp_id == 0) {
                $.ajax({
                    url      : '/api/hpc7000',
                    type     : 'post',
                    complete : function(jqxhr, status) {
                        if (status === 'success') {
                            var sp = JSON.parse(jqxhr.responseText);
                            $form.find('#input_service_provider_id').val(sp.pk);
                            data['service_provider_id'] = sp.pk;
                            kfw.submit(data, $form, opts);
                        }
                        else {
                            onerror();
                        }
                    }
                });
            } else {
                kfw.submit(data, $form, opts);
            }
        },
    });
    kfw.content.on('dialogopen', function(event) {
        var form        = $(event.currentTarget).find('form');
        var sp_id_input = form.find('#input_service_provider_id');
        var sp_id       = sp_id_input.val();
        if (sp_id == null || sp_id === '') {
            sp_id_input.val(0);
        }
    });
    kfw.start();
}

function blades_list(cid, eid) {
    require('KIM/hosts.js');
    hosts_list(cid, eid);
}

function blade_manager_list(cid) {
    create_grid({
        content_container_id : cid,
        grid_id              : 'blades_list',
        url                  : '/api/hpcmanager?expand=service_provider',
        colNames             : [ 'Id', 'Label', 'BladeSystem IP', 'VirtualConnect IP', '' ],
        colModel             : [
            { name : 'pk', index : 'pk', hidden : true, key : true, sorttype : 'int' },
            { name : 'label', index : 'label' },
            { name : 'bladesystem_ip', index : 'bladesystem_ip' },
            { name : 'virtualconnect_ip', index : 'virtualconnect_ip' },
            { name : 'synchronize', index : 'synchronize', width : 40, align : 'center', nodetails : true }
        ],
        details              : { tabs : [
            { label : 'Blades', id : 'blades', onLoad : blades_list }
        ] },
        afterInsertRow       : function(grid, rowid, rowdata, rowelem) {
            var sp_id  = rowelem.service_provider.service_provider_id;
            var cell   = $(grid).find('tr#' + rowid).find('td[aria-describedby="blades_list_synchronize"]');
            var button = $('<button>', { text : 'Sync', id : 'sync-hpc' }).button({ icons : { primary : 'ui-icon-refresh' } })
                                                                          .css('margin-top', '0')
                                                                          .click(function() {
                                                                              $.ajax({
                                                                                  url  : '/api/hpc7000/' + sp_id + '/synchronize',
                                                                                  type : 'POST'
                                                                              });
                                                                          }).appendTo(cell);
            button     = $('<button>', { text : 'Edit', id : 'edit-hpc' }).button({ icons : { primary : 'ui-icon-wrench' } })
                                                                          .css('margin-top', '0')
                                                                          .click(function() { add_hpc(rowid); }).appendTo(cell);
        }
    });

    var _actions = $('#' + cid).prevAll('.action_buttons');
    $('<a>', { text : 'Add HP C7000' }).button({ icons : { primary : 'ui-icon-plusthick' } })
                                       .appendTo(_actions).bind('click', add_hpc);
}
