/*
 * Allow clone and import of objects in a service provider (sp_id)
 * Display all object of specified type (sorted by service provider)
 * Only display service providers with the same collector manager than dest service provider
 * Allow user to select objects and import them
 *
 * @param container_id id of the dom elment to add the import button
 * @param sp_id        id of the service provider where to import selected objects
 * @param obj_info     hash of type info of objects to import :
 *      type        : object type (format as table name). Used also to compute object api route (by removing '_')
 *      name        : object user friendly name
 *      label_attr  : name of the object label attr
 *      desc_attr   : name of the object description attr
 * @param grid_ids     list of id of grid to refresh after import
 */
function importItemButton(container_id, sp_id, obj_info, grid_ids) {
    var collector_manager_id;

    function loadItemTree() {
        // Build items tree
        var items_tree = [];
        var sp_treated = 0;

        $('body').css('cursor', 'wait');

        function addServiceProviderItems(i,sp) {
            // Do not list destination service provider
            if (sp.pk != sp_id) {
                // List only service providers with the same collector manager than dest service provider
                $.get('/api/serviceprovider/' + sp.pk + '/service_provider_managers?custom.category=CollectorManager')
                .success(function(manager) {
                    if (manager.length > 0 && manager[0].manager_id === collector_manager_id) {
                        // Get related items and add them to the tree
                        $.get('/api/' + obj_info.type.replace(/_/g,'') + '?service_provider_id=' + sp.pk).success( function(related) {
                            var items = [];
                            $.each(related, function(i,item) {
                                items.push({
                                    data : item[obj_info.label_attr],
                                    attr : {
                                        item_id     : item.pk,
                                        item_desc   : item[obj_info.desc_attr]
                                    }
                                });
                            });
                            // Add only service with items
                            if (items.length > 0) {
                                items_tree.push( {
                                    data        : sp.label,
                                    children    : items
                                } );
                            }
                            sp_treated++;
                        });
                    } else { sp_treated++ }
                });
            } else { sp_treated++ }
        }

        $.get('/api/serviceprovider').success( function(serviceproviders) {
            var sp_count   = serviceproviders.length;

            $.each(serviceproviders, addServiceProviderItems);

           // Wait end of tree building and then display tree
            function displayTree() {
                if (sp_count == sp_treated) {
                    var browser = $('<div>');
                    var msg     = $('<span>', {
                        html : 'Select '
                                + obj_info.name
                                + 's to import from existing services.<br>Both services must have the same collector manager.'
                    });
                    browser.append(msg).append($('<hr>'));
                    var tree_cont   = $('<div>', {style : 'height:300px;overflow:auto'}).appendTo(browser);
                    var item_detail = $('<div>').appendTo(browser);
                    require('jquery/jquery.jstree.js');
                    tree_cont.jstree({
                        "plugins"   : ["themes","json_data", "ui", "checkbox"],
                        "themes"    : {
                            url : "css/jstree_themes/default/style.css",
                            icons : false
                        },
                        "json_data" : {
                            "data"                  : items_tree,
                            "progressive_render"    : true
                        }
                    }).bind("hover_node.jstree", function (event, data) {
                        var node = data.rslt.obj;
                        if (node.attr('item_id')) {
                            item_detail.html('Description: ' + node.attr("item_desc"));
                        }
                    }).bind("dehover_node.jstree", function (event, data) {
                        item_detail.html('');
                    });

                    $('body').css('cursor', 'default');

                    function importChecked() {
                        $('body').css('cursor', 'wait');
                        var checked_items = tree_cont.jstree('get_checked',null,true)
                        var treated_count = 0;
                        checked_items.each( function() {
                            var item_id     = $(this).attr('item_id');
                            var obj_route   = obj_info.type.replace(/_/g,'');
                            var data        = {service_provider_id : sp_id};
                            data[obj_info.type + '_id'] = item_id;
                            if (item_id) {
                                $.ajax({
                                    type    : 'POST',
                                    url     : '/api/' + obj_route,
                                    data    : data,
                                    success : function () { treated_count++ },
                                    error   : function (error) {alert(error.responseText)}
                                });
                            } else {
                                treated_count++;
                            }
                        });
                        function endImport() {
                            if (treated_count == checked_items.length) {
                                $('body').css('cursor', 'default');
                                $.each(grid_ids, function(i,grid_id) {
                                    $('#'+grid_id).trigger('reloadGrid');
                                });
                                browser.dialog("close");
                            } else {
                                setTimeout(endImport, 10);
                            }
                        }
                        endImport();
                    }

                    // Show dialog
                    browser.dialog({
                        title   : 'Import ' + obj_info.name + 's',
                        modal   : true,
                        width   : '400px',
                        buttons : [
                            {id:'button-import',text:'Import',click : importChecked},
                            {id:'button-cancel',text:'Cancel' ,click: function () {$(this).dialog("close");}}
                        ]    
                        ,
                        close: function (event, ui) {
                            $(this).remove();
                        }
                    });
                } else {
                    setTimeout(displayTree, 10);
                }
            }
            displayTree()
        });
    }

    // Retrieve collector manager id (used to check available service providers for import)
    // Add import button only if there is a linked collector manager
    $.get('/api/serviceprovider/' + sp_id + '/service_provider_managers?custom.category=CollectorManager')
    .success(function(manager) {
        if (manager.length > 0) {
            collector_manager_id = manager[0].manager_id;

            // Create and bind import button
            $("<button>", {html : 'Import ' + obj_info.name + 's'})
            .button({ icons : { primary : 'ui-icon-plusthick' } })
            .appendTo('#' + container_id)
            .click( loadItemTree );
        }
    });
}