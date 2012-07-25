require('modalform.js');
require('KIO/services.js');
require('KIO/services_config.js');

function getAllConnectorFields() {
    return {
        'activedirectory'   : {
            ad_host             : {
                label   : 'Domain controller',
                help    : 'Could be the Domain Controller name or the Domain Name'
            },
            ad_user             : {
                label   : 'User@domain'
            },
            ad_usessl           : {
                label   : 'Use SSL ?',
                type    : 'checkbox'
            }
        },
        'scom'              : {
            scom_ms_name        : {
                label   : 'Root Management Server FQDN'
            },
            scom_usessl         : {
                label   : 'Use SSL ?',
                type    : 'checkbox'
            },
        },
        'sco'               : {},
        'mockmonitor'       : {}
    };
}

function deleteService(eid) {
    $.ajax({
        url     : '/api/connector?service_provider_id=' + eid,
        success : function(data) {
            if (data.length <= 0) {
                $.ajax({
                    url     : '/api/serviceprovider/' + eid,
                    type    : 'DELETE'
                });
            }
        }
    });
}

function getPossibleConnectorTypes(eid) {
    var types   = [ 'DirectoryServiceManager', 'WorkflowManager', 'Collectormanager' ];
    var ret     = [];
    for (var i in types) if (types.hasOwnProperty(i)) {
        if (!isThereAConnector(eid, types[i])) {
            ret.push(types[i]);
        }
    }
    return ret;
}

function connectConnectorForm(eid, type, id, cb) {
    if (type != null && id == null)
        return;
    cb  = cb || $.noop;
    var modal;
    if (type == null) {
        var selectType  = $('<select>');
        var types       = getPossibleConnectorTypes(eid);
        if (types.length <= 0)
            return;
        var selectConn  = $('<select>');
        var upperDiv    = $('<div>').append(selectType).append(selectConn);
        for (var i in types) if (types.hasOwnProperty(i)) {
            $(selectType).append($('<option>', { text : types[i] }));
        }
        $(selectType).bind('change', function(event) {
            $.ajax({
                url     : '/api/connectortype?connector_category=' + $(event.currentTarget).val(),
                success : function(data) {
                    $(selectConn).empty();
                    for (var i in data) if (data.hasOwnProperty(i)) {
                        $(selectConn).append($('<option>', { text : data[i].connector_name }));
                    }
                    $(selectConn).trigger('change');
                }
            });
        });
        $(selectType).trigger('change');
        $(selectConn).bind('change', function(event) {
            var tmp     = ($(event.currentTarget).val()).toLowerCase();
            var fields      = getAllConnectorFields()[tmp];
            fields.service_provider_id  = { value : eid, type : 'hidden' };
            var tmpmod  = new ModalForm({
                name    : tmp,
                fields  : fields,
                cancel  : function() { deleteService(eid); },
                callback: function() { $('#technicalserviceslistgrid').trigger('reloadGrid'); cb(); }
            });
            $(modal.form).remove();
            modal.form  = tmpmod.form;
            modal.handleArgs(tmpmod.exportArgs());
            $(modal.content).append(modal.form);
            modal.startWizard();
        });
    }
    var fields      = getAllConnectorFields()[(type != null) ? type : 'activedirectory'];
    fields.service_provider_id  = { value : eid, type : 'hidden' };
    var prependel   = (type != null) ? undefined : upperDiv;
    modal           = new ModalForm({
        title           : (type != null) ? 'Configure ' + type : 'Connect to a Service',
        name            : (type != null) ? type : 'activedirectory',
        fields          : fields,
        prependElement  : prependel,
        id              : id,
        cancel          : function() { deleteService(eid); },
        callback        : function() { $('#technicalserviceslistgrid').trigger('reloadGrid'); cb(); }
    });
    modal.start();
}

function addTechnicalServiceButton(container) {
    var button  = $("<a>", { text : 'Create a Technical Service' }).button({ icons : { primary : 'ui-icon-plusthick' } }).appendTo(container);
    var service_fields  = {
        externalcluster_name    : {
            label   : 'Name',
            help    : "Name which identify your service"
        },
        externalcluster_desc    : {
            label   : 'Description',
            type    : 'textarea'
        }
    };
    var service_opts    = {
        title       : 'Create a Technical Service',
        name        : 'externalcluster',
        fields      : service_fields,
        beforeSubmit: function() {
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
        },
        callback    : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
            connectConnectorForm(data.pk);
        },
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        }
    };
    $(button).click(function() { (new ModalForm(service_opts)).start() });
}

function technicalservicedetails(cid, eid) {
    var container   = $('#' + cid);
    var table       = $('<table>').appendTo(container);
    $.ajax({
        url     : '/api/connector?service_provider_id=' + eid,
        success : function(data) {
            var multi   = (data.length > 1);
            for (var i in data) if (data.hasOwnProperty(i)) {
                $.ajax({
                    url     : '/api/connectortype/' + data[i].connector_type_id,
                    async   : false,
                    success : function(datatype) {
                        var d   = data[i];
                        var line            = $('<tr>').appendTo(table);
                        $(line).append($('<td>', { text : datatype.connector_category + ' : ' + datatype.connector_name }).css('vertical-align', 'middle'));
                        var configureButton = $('<a>', { text : 'Configure' }).button({ icons : { primary : 'ui-icon-wrench' } });
                        $(configureButton).bind('click', function() { connectConnectorForm(eid, (datatype.connector_name).toLowerCase(), d.pk, function() {
                            $(container).empty();
                            technicalservicedetails(cid, eid);
                        }) });
                        $(line).append($('<td>').append(configureButton));
                        var deleteButton;
                        if (multi) {
                            deleteButton    = $('<a>', { text : 'Delete' }).button({ icons : { primary : 'ui-icon-trash' } });
                            $(deleteButton).bind('click', function() {
                                $.ajax({
                                    url     : '/api/connector/' + d.pk,
                                    type    : 'DELETE',
                                    success : function() {
                                        $(container).empty();
                                        technicalservicedetails(cid, eid);
                                    }
                                });
                            });
                        }
                        $(line).append($('<td>').append(deleteButton));
                    }
                });
            }
        }
    });
    var addButton   = $('<a>', { text : 'Connect to a Service' }).button({ icons : { primary : 'ui-icon-transferthick-e-w' } });
    $(addButton).appendTo(container).bind('click', function() { connectConnectorForm(eid, null, null, function() {
        $(container).empty();
        technicalservicedetails(cid, eid);
    });});
}

function technicalserviceslist(cid) {
    var container   = $('#' + cid);
    create_grid({
        url                     : '/api/externalcluster',
        content_container_id    : cid,
        grid_id                 : 'technicalserviceslistgrid',
        colNames                : [ 'ID', 'Name' ],
        colModel                : [
            { name : 'pk', index : 'pk', width : 60, sorttype : 'int', hidden : true, key : true },
            { name : 'externalcluster_name', index : 'service_name', width : 200 }
        ],
        afterInsertRow          : function(grid, rowid, rowdata) {
            $.ajax({
                url     : '/api/connector?service_provider_id=' + rowdata.pk,
                success : function(data) {
                    if (data.length <= 0) {
                        $(grid).delRowData(rowid);
                    }
                }
            });
        },
        details                 : {
            tabs    : [
                { label : 'Connectors', onLoad : technicalservicedetails }
            ]
        }
    });
    addTechnicalServiceButton(container);
}
