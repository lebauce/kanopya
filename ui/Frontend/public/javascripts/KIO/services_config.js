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

            if (isThereAManager(elem_id, 'directory_service_manager') === false) {
                createManagerButton('DirectoryServiceManager', 'directory_service_manager', ctnr, elem_id, container_id);
            }

        }
    });
}

function _managerParams() {
    var params  = {
        'ad_nodes_base_dn'  : 'Nodes container DN'
    };

    return (function(name) {
        return params[name];
    });
}
var managerParams = _managerParams();

function createmanagerDialog(connectortype, managertype, sp_id, callback, skippable) {
    var that    = this;
    callback    = callback || $.noop;
    $.ajax({
        url         : '/api/serviceprovider/' + sp_id + '/findManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'category' : connectortype }),
        success     : function(data) {
            if (data.length <= 0) {
                if (skippable) callback();
                else return;
            }
            var select  = $("<select>", { name : 'managerselection' })
            var fieldset= $('<fieldset>').css({'border' : 'none'});
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
            $(select).bind('change', function(event) {
                $(fieldset).empty();
                $.ajax({
                    url     : '/api/entity/' + $(event.currentTarget).val() + '/getManagerParamsDef',
                    type    : 'POST',
                    success : function(data) {
                        for (var i in data) if (data.hasOwnProperty(i)) {
                            $(fieldset).append($('<label>', {
                                text : managerParams(data[i]) + " : ",
                                for : data[i]
                            })).append($("<input>", { name : data[i], id : data[i] }));
                        }
                    }
                });
            });
            $(select).trigger('change');
            $("<div>").append($(select)).append(fieldset).appendTo('body').dialog({
                title           : 'Add a ' + connectortype,
                closeOnEscape   : false,
                draggable       : false,
                resizable       : false,
                modal           : true,
                buttons         : {
                    'Cancel'    : function() { $(this).dialog("destroy"); if (skippable) callback(); },
                    'Ok'        : function() {
                        var dial    = this;
                        var data    = {
                            manager_type        : managertype,
                            manager_id          : $(select).attr('value')
                        };
                        var params  = {};
                        var ok      = true;
                        $(fieldset).find(':input').each(function() {
                            if ($(this).val() == null || $(this).val() === '') {
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
                                var dialog = $("<div>", { id : "waiting_default_insert", title : "Initializing configuration", text : "Please wait..." });
                                dialog.css('text-align', 'center');
                                dialog.appendTo("body").dialog({
                                    draggable   : false,
                                    resizable   : false,
                                    title       : ""
                                });
                                $(dialog).parents('div.ui-dialog').find('span.ui-icon-closethick').remove();
                            }, 10);
                            $.ajax({
                                url           : '/api/serviceprovider/' + sp_id + '/addManager',
                                type          : 'POST',
                                contentType   : 'application/json',
                                data          : JSON.stringify(data),
                                success       : function() {
                                    $(dial).dialog("destroy");
                                    callback();
                                },
                                complete      : function() {
                                    $("div#waiting_default_insert").dialog("destroy");
                                },
                                error         : function() {
                                    if (skippable) callback();
                                }
                            });
                        }
                    }
                }
            });
        }
    });
}

function createManagerButton(connectortype, managertype, ctnr, sp_id, container_id) {
    var addManagerButton    = $("<a>", { text : 'Add a ' + connectortype }).button({ icons : { primary : 'ui-icon-plusthick' } });
    var that                = this;
    var reload = function() {
        $('#' + container_id).empty();
        that.loadServicesConfig(container_id, sp_id);
    };
    addManagerButton.bind('click', function() {
        createmanagerDialog(connectortype, managertype, sp_id, reload);
    });
    addManagerButton.appendTo($(ctnr));
    $(ctnr).append("<br />");
}
