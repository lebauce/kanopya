require('common/formatters.js');

//Check if there is a configured connector
function isThereAConnector(elem_id, connector_category) {
    var is  = false;
    // Get all configured connectors on the service
    $.ajax({
        async   : false,
        url     : '/api/connector?service_provider_id=' + elem_id,
        success : function(connectors) {
            for (i in connectors) if (connectors.hasOwnProperty(i)) {
                // Get the connector type for each
                $.ajax({
                    async   : false,
                    url     : '/api/connectortype?connector_type_id=' + connectors[i].connector_type_id,
                    success : function(data) {
                        if (data[0].connector_category === connector_category) {
                            is  = true;
                        }
                    }
                });
                if (is) {
                    break;
                }
            }
        }
    });
    return is;
}

function isThereAManager(elem_id, category) {
    var is  = false;

    $.ajax({
        url         : '/api/serviceprovider/' + elem_id + '/getManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'manager_type' : category }),
        async       : false,
        success     : function(data) {
            is  = true;
        }
    });
    return is;
}

function loadServicesConfig (container_id, elem_id) {
    var container = $('#' + container_id);
    var externalclustername = '';
    
    var connectorsTypeHash = {};
    var connectorsTypeArray = new Array;
    
    var that = this;

    $.ajax({
        url     : '/api/serviceprovider/' + elem_id,
        type    : 'GET',
        success : function(data) {
            var external    = "";
            if (data.externalcluster_id != null) external = 'external';
            var table   = $("<table>").css("width", "100%").appendTo(container);
            $(table).append($("<tr>").append($("<td>", { colspan : 2, class : 'table-title', text : "General" })));
            $(table).append($("<tr>").append($("<td>", { text : 'Name :', width : '100' })).append($("<td>", { text : data[external + 'cluster_name'] })));
            $(table).append($("<tr>").append($("<td>", { text : 'Description :' })).append($("<td>", { text : data[external + 'cluster_desc'] })));
            $(table).append($("<tr>", { height : '15' }).append($("<td>", { colspan : 2 })));
        }
    });

    $.ajax({
        url: '/api/connectortype?dataType=jqGrid',
        async   : false,
        success: function(connTypeData) {
                $(connTypeData.rows).each(function(row) {
                    //connectorsTypeHash = { 'pk' : connTypeData.rows[row].pk, 'connectorName' : connTypeData.rows[row].connector_name };
                    var pk = connTypeData.rows[row].pk;
                    connectorsTypeArray[pk] = {
                        name        : connTypeData.rows[row].connector_name,
                        category    : connTypeData.rows[row].connector_category
                    };
                });
            }
    });

    $.ajax({
        url: '/api/connector?dataType=jqGrid&service_provider_id=' + elem_id,
        success: function(data) {
            var ctnr    = $("<div>", { id : 'connectorslistcontainer', 'class' : 'details_section' });
            $(ctnr).appendTo(container);
            $(container).append($('<br />'));
            var table = $("<table>", { id : "connectorslist" }).prependTo(ctnr);
            $(table).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Connectors" })));
            $(data.rows).each(function(row) {
                var connectorTypePk = data.rows[row].connector_type_id;
                var connectorName = connectorsTypeArray[connectorTypePk].name || 'UnknownConnector';
                var tr  = $("<tr>", {
                    rel : connectorName.toLowerCase() + "|" + connectorsTypeArray[connectorTypePk].category.toLowerCase()
                }).append($("<td>", {
                    text : connectorsTypeArray[connectorTypePk].category + " :"
                }).css('padding-top', '6px')).append($("<td>", { text : connectorName }).css('padding-top', '6px'));
                var confButton  = $("<a>", { text : 'Configure', rel : data.rows[row].pk, 'class' : 'no-margin' });
                var delButton   = $("<a>", { text : 'Delete', rel : data.rows[row].pk, 'class' : 'no-margin' });
                $(tr).append($("<td>").append($(confButton))).append($("<td>").append($(delButton)));
                $(tr).appendTo(table);

                // Bind configure and delete actions on buttons
                $(confButton).bind('click', { button : confButton }, function(event) {
                    var button  = $(event.data.button);
                    var id      = $(button).attr('rel');
                    var name    = $(button).parents('tr').attr('rel').split('|');
                    if (name[0] === 'sco') {
                        that.scoConfigurationDialog(elem_id, id);
                    } else {
                        that.createSpecServDialog(elem_id, name[0], false, name[1], undefined, id).start();
                    }
                }).button({ icons : { primary : 'ui-icon-wrench' } });
                $(delButton).bind('click', { button : delButton }, function(event) {
                    var button  = $(event.data.button);
                    $.ajax({
                        type    : 'delete',
                        url     : '/api/' + button.parents('tr').attr('rel').split('|')[0] + '/' + button.attr('rel'),
                        success : function() {
                            $(container).empty();
                            that.loadServicesConfig(container_id, elem_id);
                        }
                    });
                }).button({ icons : { primary : 'ui-icon-trash' } });
            });

            if (isThereAConnector(elem_id, 'DirectoryService') === false) {
                var b   = $("<a>", { text : 'Add a Directory Service', id : 'adddirectory' });
                b.bind('click', function() { createMonDirDialog(elem_id, 'DirectoryService').start(); });
                b.appendTo($(ctnr)).button({ icons : { primary : 'ui-icon-plusthick' } });
            }
            
            if (isThereAConnector(elem_id, 'Collectormanager') === false) {
                var b  = $("<a>", { text : 'Add a Monitoring Service', id : 'addmonitoring' });
                b.bind('click', function() { createMonDirDialog(elem_id, 'Collectormanager').start(); });
                $(ctnr).append($("<br />"));
                b.appendTo($(ctnr)).button({ icons : { primary : 'ui-icon-plusthick' } });
            }
        
            if (isThereAConnector(elem_id, 'WorkflowManager') === false) {
                var b   = $("<a>", { text : 'Add a Workflow Connector', id : 'addworkflowmanager' });
                b.bind('click', function() { createMonDirDialog(elem_id, 'WorkflowManager').start(); });
                $(ctnr).append($("<br />"));
                b.appendTo($(ctnr)).button({ icons : { primary : 'ui-icon-plusthick' } });
            }
        }
    });

    $.ajax({
        url     : '/api/serviceprovidermanager?service_provider_id=' + elem_id,
        success : function(data) {
            var ctnr    = $("<div>", { id : "managerslistcontainer", 'class' : 'details_section' });
            $(ctnr).appendTo($(container));
            var table   = $("<table>", { id : 'managerslist' }).prependTo($(ctnr));
            $(table).append($("<tr>").append($("<td>", { colspan : 3, class : 'table-title', text : "Managers" })));

            for (var i in data) if (data.hasOwnProperty(i)) {
                $.ajax({
                    url       : '/api/entity/' + data[i].manager_id,
                    async     : false,
                    success   : function(mangr) {
                        $.ajax({
                            url     : '/api/serviceprovider/' + mangr.service_provider_id,
                            async   : false,
                            success : function(sp) {
                                var l   = $("<tr>", { text : data[i].manager_type + " : " + ((sp.externalcluster_name != null) ? sp.externalcluster_name : sp.cluster_name) });
                                $(table).append(l);
                                $.ajax({
                                    url     : '/api/connector/' + mangr.pk,
                                    success : function(conn) {
                                        if (conn.connector_type_id != null) {
                                            $.ajax({
                                                url     : '/api/connectortype/' + conn.connector_type_id,
                                                success : function(conntype) {
                                                    $(l).text($(l).text() + ' - ' + conntype.connector_name);
                                                }
                                            });
                                        }
                                    }
                                });
                            }
                        });
                    }
                });
            }

            if (isThereAManager(elem_id, 'workflow_manager') === false) {
                createManagerButton('WorkflowManager', 'workflow_manager', ctnr, elem_id, container_id);
            }

            if (isThereAManager(elem_id, 'collector_manager') === false) {
                createManagerButton('Collectormanager', 'collector_manager', ctnr, elem_id, container_id);
            }

        }
    });
}

function createManagerButton(connectortype, managertype, ctnr, sp_id, container_id) {
    var that = this;
    var container = $('#' + container_id);

    var addManagerButton    = $("<a>", { text : 'Add a ' + connectortype }).button({ icons : { primary : 'ui-icon-plusthick' } });
    addManagerButton.bind('click', function() {
        $.ajax({
            url         : '/api/serviceprovider/' + sp_id + '/findManager',
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify({ 'category' : connectortype }),
            success     : function(data) {
                if (data.length <= 0) return;
                var select  = $("<select>", { name : 'managerselection' })
                for (var i in data) if (data.hasOwnProperty(i)) {
                    var theName     = data[i].name;
                    var manager     = data[i];
                    $.ajax({
                        url     : '/api/externalcluster/' + data[i].service_provider_id,
                        async   : false,
                        success : function(data) {
                            if (data.externalcluster_name != null) {
                                theName = data.externalcluster_name + " - " + theName;
                            }
                            $(select).append($("<option>", { text : theName, value : manager.id }));
                        }
                    });
                }
                $("<fieldset>").append($(select)).appendTo(container).dialog({
                    title           : 'Add a ' + connectortype,
                    closeOnEscape   : false,
                    draggable       : false,
                    resizable       : false,
                    buttons         : {
                        'Cancel'    : function() { $(this).dialog("destroy"); },
                        'Ok'        : function() {
                            var dial    = this;
                            $.ajax({
                                url         : '/api/serviceprovidermanager',
                                type        : 'POST',
                                data        : {
                                    manager_type        : managertype,
                                    manager_id          : $(select).attr('value'),
                                    service_provider_id : sp_id,
                                },
                                success     : function() {
                                    $(dial).dialog("destroy");
                                    $(container).empty();
                                    that.loadServicesConfig(container_id, sp_id);
                                }
                            });
                        }
                    }
                });
        }
      });
    });
    addManagerButton.appendTo($(ctnr));
    $(ctnr).append("<br />");
}
