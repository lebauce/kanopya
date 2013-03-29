require('common/formatters.js');
require('common/service_common.js');

//Check if there is a configured connector
function isThereAConnector(elem_id, connector_category) {
    var is  = false;
    // Get all configured connectors on the service
    var filter = 'component_type.component_type_categories.component_category.category_name=' + connector_category;
    $.ajax({
        async   : false,
        url     : '/api/component?service_provider_id=' + elem_id + '&' + filter,
        success : function(connectors) {
            if (connectors.length > 0) {
                is = true;
            }
        }
    });
    return is;
}

function isThereAManager(elem_id, category) {
    var manager = undefined;

    $.ajax({
        url         : '/api/serviceprovider/' + elem_id + '/service_provider_managers?expand=manager&custom.category=' + category,
        type        : 'GET',
        async       : false,
        success     : function(data) {
            if (data[0]) {
                manager = data[0].manager;
            }
        }
    });
    return manager;
}

function deleteManager(pk, container_id, elem_id) {
    $.ajax({
        url     : '/api/serviceprovidermanager/' + pk,
        type    : 'DELETE',
        success : function() {
            $('#' + container_id).empty();
            loadServicesConfig(container_id, elem_id);
        }
    });
}

function loadServicesConfig (container_id, elem_id) {
    var container = $('#' + container_id);
    var connectors = [];

    // Service details
    var table = $("<table>").css("width", "100%").appendTo(container);
    var expand = 'expand=service_provider_managers.manager_category,service_provider_managers.manager.service_provider,service_provider_managers.manager.component_type';
    $.ajax({
        url     : '/api/serviceprovider/' + elem_id + '?' + expand,
        type    : 'GET',
        success : function(serviceprovider) {
            var external = "";
            if (serviceprovider.externalcluster_id != null) external = 'external';

            // Add the General div to display name and desc.
            $(table).append($("<tr>").append($("<td>", { colspan : 2, class : 'table-title', text : "General" })));
            $(table).append($("<tr>").append($("<td>", { text : 'Name :', width : '100' })).append($("<td>", { text : serviceprovider[external + 'cluster_name'] })));
            $(table).append($("<tr>").append($("<td>", { text : 'Description :' })).append($("<td>", { text : serviceprovider[external + 'cluster_desc'] })));
            $(table).append($("<tr>", { height : '15' }).append($("<td>", { colspan : 2 })));

            // Add the Managers div
            var ctnr = $("<div>", { id : "managerslistcontainer", 'class' : 'details_section' });
            $(ctnr).appendTo($(container));
            var managers = $("<table>", { id : 'managerslist' }).prependTo($(ctnr));
            $(managers).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Managers" })));

            // Display each manager infos
            for (var index in serviceprovider.service_provider_managers) {
                var spmanager = serviceprovider.service_provider_managers[index];
                var sp = spmanager.manager.service_provider

                // Manager type + connector provider name
                var line = $("<tr>");
                $("<td>", { text : spmanager.manager_category.category_name + ' : ' }).css('vertical-align', 'middle').appendTo(line);
                var std = $("<td>", { text : (sp.externalcluster_name != null) ? sp.externalcluster_name : sp.cluster_name }).appendTo(line);
                $(std).css('vertical-align', 'middle');

                // Configuration button
                $.ajax({
                    url     : '/api/component/' + spmanager.manager.pk + '/getManagerParamsDef',
                    type    : 'POST',
                    async   : false,
                    success : function(manager_params) {
                        if (Object.keys(manager_params).length > 0) {
                            $("<td>").append($("<a>", { text : 'Configure' }).button({ icons : { primary : 'ui-icon-wrench' } })).bind('click', { manager : spmanager }, function(event) {
                                var manager = event.data.manager;
                                createmanagerDialog(manager.manager_category.category_name, elem_id, $.noop, false, manager.pk, manager.manager_id);
                            }).appendTo(line);

                        } else {
                            // Don't show configuration button if no parameters for this manager
                            $("<td>").appendTo(line);
                        }
                    }
                });

                // Deletion button
                $("<td>").append($("<a>", { text : 'Delete' }).button({ icons : { primary : 'ui-icon-trash' } }).bind('click', { pk : spmanager.pk }, function(event) {
                    deleteManager(event.data.pk, container_id, elem_id);
                })).appendTo(line);
                $(managers).append(line);

                // Concrete connector type name
                $(std).text($(std).text() + ' - ' + spmanager.manager.component_type.component_name);

                // Update the connector list for further use
                connectors.push(spmanager.manager_category.category_name);
            }

            var categories = [ 'WorkflowManager', 'CollectorManager', 'DirectoryServiceManager' ];
            for (var category in categories) {
                if ($.inArray(categories[category], connectors) < 0) {
                    createManagerButton(categories[category], ctnr, elem_id, container_id);
                }
            }
        }
    });
}

/*
 * We manage here param info/def for all possible manager params of all managers
 * UGLY
 * TODO other (same mecanism as attr_def)
 */
function _managerParams() {
    var params  = {
        'ad_nodes_base_dn'  : { label : 'Nodes container DN', mandatory : 1 },
        'mockmonit_config'  : { label : 'Configuration', type : 'textarea' }
    };

    return (function(name) {
        return params[name] ? params[name] : { label : name };
    });
}
var managerParams = _managerParams();

function createmanagerDialog(managertype, sp_id, callback, skippable, instance_id, comp_id) {
    var that        = this;
    var mode_config = instance_id && instance_id > 0;
    callback        = callback || $.noop;
    connectortype   = managertype;

    // Retrieve kanopya cluster to exclude it from manager search
    var kanopya_cluster_id;
    $.ajax({
        url     : '/api/cluster?cluster_name=Kanopya',
        async   : false,
        success : function(kanopya_cluster) {
            kanopya_cluster_id = kanopya_cluster[0].pk;
        }
    });

    // we skip all managers of the Kanopya cluster
    var managers = findManager(connectortype, kanopya_cluster_id, true);

    if (managers.length <= 0) {
        if (skippable) callback();
        else {
            alert('No technical service connected to a ' + connectortype + '.\nSee: Administration -> Technical Services');
        }
        return;
    }
    var select  = $("<select>", { name : 'managerselection' })
    var fieldset= $('<fieldset>').css({'border' : 'none'});

    for (var i in managers) if (managers.hasOwnProperty(i)) {
        var theName = managers[i].component_type ? managers[i].component_type.component_name : managers[i].connector_type.connector_name;
        var manager = managers[i];
        $.ajax({
            url     : '/api/serviceprovider/' + managers[i].service_provider_id,
            async   : false,
            success : function(data) {
                if (data.label != null) {
                    theName = data.label + " - " + theName;
                }
                $(select).append($("<option>", { text : theName, value : manager.pk }));
            }
        });
    }
    $(select).bind('change', function(event) {
        $(fieldset).empty();
        var manager_id = $(event.currentTarget).val();
        $.ajax({
            url     : '/api/entity/' + manager_id + '/getManagerParamsDef',
            type    : 'POST',
            success : function(data) {
                var current_params = {};
                if (mode_config) {
                    $.ajax({
                        url     : '/api/serviceprovider/' + sp_id + '/getManagerParameters',
                        type    : 'POST',
                        async   : false,
                        data    : { manager_type : managertype },
                        success : function(manager_params) {
                            current_params = manager_params;
                        }
                    });
                }
                for (var i in data) if (data.hasOwnProperty(i)) {
                    $(fieldset).append($('<label>', {
                        text : managerParams(data[i]).label + " : ",
                        for : data[i]
                    })).append($('<'+ (managerParams(data[i]).type || 'input') +'>',
                                { name : data[i], id : data[i], value : current_params[data[i]] })
                    );

                    // Specific management for custom form
                    if (connectortype == 'DirectoryServiceManager' && data[i] == 'ad_nodes_base_dn') {
                        $(fieldset).append('<br>');
                        $(fieldset).append($('<button>', {html : 'browse...'}).click( {manager_id : manager_id }, ActiveDirectoryBrowser ));
                        $(fieldset).append($('<button>', {html : 'search...'}).click( {manager_id : manager_id }, ActiveDirectorySearch ));
                    }
                }
            }
        });
    });

    // Don't show the manager dropdown list if we are configuring an alredy linked manager instance
    // Set the value to the correct manager id (used to load params)
    if (mode_config) {
        $(select).val(comp_id);
        $(select).hide();
    }
    $(select).trigger('change');

    $("<div>").append($(select)).append(fieldset).appendTo('body').dialog({
        title           : mode_config ? connectortype + ' configuration' : 'Link to a ' + connectortype,
        closeOnEscape   : false,
        resizable       : false,
        modal           : true,
        buttons         : {
            'Cancel'    : function() {
                $(this).dialog("destroy");
                if (skippable) callback();
            },
            'Ok'        : function() {
                var dial    = this;
                var data    = {
                    manager_type        : managertype,
                    manager_id          : $(select).attr('value')
                };
                var params  = {};
                var ok      = true;
                $(fieldset).find(':input:not(:button)').each(function() {
                    if ( managerParams($(this).attr('name')).mandatory && ($(this).val() == null || $(this).val() === '')) {
                      ok                            = false;
                    } else {
                      params[$(this).attr('name')]  = $(this).val();
                    }
                });
                if (ok === true) {
                    if (Object.keys(params).length > 0) {
                        data.manager_params = params;
                    }
                    setTimeout(function() {
                        $('*').addClass('cursor-wait');
                        var dialog = $("<div>", { id : "waiting_default_insert", title : "Initializing configuration" });
                        dialog.addClass('waiting-insert-content-container').append(
                            $('<div>').addClass('waiting-insert-content')
                                .append( $('<img>', {alt : "Loading, please wait", src : "/css/theme/loading.gif"}) )
                                .append( $('<p>', {html : "Please wait ..."}) )
                        );
                        dialog.appendTo("body").dialog({
                            resizable   : false,
                            draggable   : false
                        });
                        $(dialog).parents('div.ui-dialog').find('.ui-dialog-titlebar-close').remove();
                    }, 10);

                    var url;
                    var post_data;
                    if (mode_config) {
                        url         = '/api/serviceprovider/' + sp_id + '/addManagerParameters';
                        post_data   = {
                                manager_type : managertype,
                                params       : data.manager_params,
                                override     : 1
                        };
                    } else {
                        url         = '/api/serviceprovider/' + sp_id + '/addManager';
                        post_data   = data;
                    }
                    $.ajax({
                        url           : url,
                        type          : 'POST',
                        contentType   : 'application/json',
                        data          : JSON.stringify(post_data),
                        success       : function() {
                            $(dial).dialog("destroy");
                            callback();
                        },
                        complete      : function() {
                            $('*').removeClass('cursor-wait');
                            $("div#waiting_default_insert").dialog("destroy");
                        },
                        error         : function(error) {
                            if (skippable) callback();
                        }
                    });
                }
            }
        }
    });
}

function createManagerButton(managertype, ctnr, sp_id, container_id) {
    var addManagerButton    = $("<a>", {
        text    : 'Link to a ' + managertype,
        style   : 'width:300px'
    }).button({ icons : { primary : 'ui-icon-link' } });
    var that                = this;
    var reload = function() {
        $('#' + container_id).empty();
        that.loadServicesConfig(container_id, sp_id);
    };
    addManagerButton.bind('click', function() {
        createmanagerDialog(managertype, sp_id, reload, false, 0);
    });
    addManagerButton.appendTo($(ctnr));
    $(ctnr).append("<br />");
}

// Build json tree as expected by jstree from ad tree
function buildADTreeJSONData(ad_tree) {
    var treedata = [];

    $.each(ad_tree, function (node_idx) {
        var node = ad_tree[node_idx];
        var treenode = {
                data        : node.name,
                attr        : { id : node.dn },
        }
        if (node.children && node.children.length > 0) {
            treenode.children = buildADTreeJSONData( node.children );
        }
        treedata.push( treenode );
    });

   return treedata;
}

function ActiveDirectoryBrowser(event) {
    var dn_input = $(this).prevAll('input');
    var ad_id    = event.data.manager_id;

    // Get AD user
    $.ajax({
        url         : '/api/entity/' + ad_id,
        async       : false,
        success     : function(data) {
            ad_user  = data.ad_user;
        }
    });

    require('common/general.js');
    callMethodWithPassword({
            login        : ad_user,
            dialog_title : "",
            url          : '/api/entity/' + ad_id + '/getDirectoryTree',
            success      : function(data) {
                require('jquery/jquery.jstree.js');
                var treedata = buildADTreeJSONData(data);

                var browser = $('<div>');
                var tree_cont = $('<div>', {style : 'height:300px'});
                var selected_dn_input = $('<input>', {style : 'width:350px'});
                browser.append(selected_dn_input);
                browser.append(tree_cont);

                tree_cont.jstree({
                    "plugins"   : ["themes","json_data","ui"],
                    "themes"    : {
                        url : "css/jstree_themes/default/style.css"
                    },
                    "json_data" : {
                        "data"                  : treedata,
                        "progressive_render"    : true
                    }
                }).bind("select_node.jstree", function (e, data) {
                    selected_dn_input.val(data.rslt.obj.attr("id"));
                });

                browser.dialog({
                    title   : 'AD Browser',
                    modal   : true,
                    width   : '400px',
                    buttons : {
                        Ok: function () {
                            dn_input.val(selected_dn_input.val());
                            $(this).dialog("close");
                        },
                        Cancel: function () {
                            $(this).dialog("close");
                        }
                    },
                    close: function (event, ui) {
                        $(this).remove();
                    }
                });
            }
    });
}

function ActiveDirectorySearch(event) {
    var dn_input = $(this).prevAll('input');
    var ad_id    = event.data.manager_id;

    var browser         = $('<div>');
    var tree_cont       = $('<div>', {style : 'height:300px'});
    var search_input    = $('<input>', { style : 'width:200px'});
    var search_button   = $('<button>', {html : 'search...'}).button({icon: {primary:'ui-icon-search'}});
    var selected_dn_input = $('<input>', {disabled:'disabled', style : 'width:300px'});

    browser.append($('<span>', {html : 'Search OU, Groups and Containers with name containing : '}))
           .append(search_input)
           .append(search_button)
           .append('<br>').append('<hr>')
           .append($('<span>', {html : 'DN : '}))
           .append(selected_dn_input)
           .append(tree_cont);

    // Get AD user
    var ad_user;
    $.ajax({
        url         : '/api/entity/' + ad_id,
        async       : false,
        success     : function(data) {
            ad_user  = data.ad_user;
        }
    });

    search_button.click( function() {
        var search_string = search_input.val();
        callMethodWithPassword({
            login        : ad_user,
            dialog_title : "",
            url          : '/api/entity/' + ad_id + '/searchDirectory',
            data         : { search_string : search_string },
            success      : function(data) {
                require('jquery/jquery.jstree.js');
                var treedata = buildADTreeJSONData(data);
                tree_cont.jstree({
                    "plugins"   : ["themes","json_data","ui"],
                    "themes"    : {
                        url : "css/jstree_themes/default/style.css"
                    },
                    "json_data" : {
                        "data"                  : treedata,
                        "progressive_render"    : true
                    }
                }).bind("select_node.jstree", function (e, data) {
                    selected_dn_input.val(data.rslt.obj.attr("id"));
                });
            }
        });
    });

    browser.dialog({
        title   : 'AD Search',
        modal   : true,
        width   : '450px',
        buttons : {
            Ok: function () {
                dn_input.val(selected_dn_input.val());
                $(this).dialog("close");
            },
            Cancel: function () {
                $(this).dialog("close");
            }
        },
        close: function (event, ui) {
            $(this).remove();
        }
    });
}
