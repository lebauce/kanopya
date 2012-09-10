require('jquery/jquery.form.js');
require('jquery/jquery.form.wizard.js');
require('common/general.js');

function createSCOWorkflowDefButton(container, managerid, dial, wfid, wf) {
    function createParameterList(parameters) {
        var list    = $("<ul>").css({
            'margin'        : '0 0 0 15px',
            'padding'       : '0',
        });
        for (i in parameters) if (parameters.hasOwnProperty(i)) {
            var li  = $("<li>", { text : parameters[i].scope_parameter_name });
            $(list).append(li);
        }
        return list;
    }

    // Create a button
    var button  = $("<a>", { text : "Create a Workflow definition" }).button({
        icons : { primary : 'ui-icon-plusthick' }
    });

    var scopes      = {};
    var scopeparams = {};
    // Retrieve all Scopes
    $.ajax({
        url     : '/api/scope',
        type    : 'get',
        success : function(data) {
            // For each Scope, retrieve all ScopeParameters
            $(data).each(function(){
                var scope   = this;
                scopes[scope.scope_name]    = scope.pk;
                $.ajax({
                    url     : '/api/scope/' + scope.pk + '/scope_parameters',
                    type    : 'get',
                    success : function(data) {
                        scopeparams[scope.pk]  = data;
                    }
                });
            });
        }
    });

    function createModal() {
        var form        = $("<form>", { id : "workflow_def_creation", action : "/api/workflowdef", method : "POST" });
        var mod         = $("<table>", { width : "100%" }).appendTo(form);

        function    changeScopeParametersList(event) {
            var value   = event.currentTarget.value;
            var cont    = $("td#scope_parameter_list");
            $(cont).empty().append(createParameterList(scopeparams[value]));
        }

        var select      = $("<select>", { id : 'param_preset_id' });
        for (i in scopes) if (scopes.hasOwnProperty(i)) {
            $(select).append($("<option>", { text : i, value : scopes[i] }));
        }
        $(select).bind('change', changeScopeParametersList);

        // Create all the form table elements
        var nameCel     = $("<td>").append($("<label>", { for : 'workflow_def_name', text : 'Name :' }));
        $(nameCel).append($("<input>", { id : 'workflow_def_name', name : 'workflow_def_name' }).css('float', 'right'));
        var firstLine   = $("<tr>");
        $(firstLine).append($("<td>").attr('width', '150').attr('height', '20').append(select)).append(nameCel);

        var pathCel     = $("<td>").append($("<label>", { for : 'directoryinput', text : "File Directory : " }));
        $(pathCel).append($("<input>", { id : 'directoryinput' }).css('float', 'right'));
        var secondLine  = $("<tr>").append($("<td>", { rowspan : 2, id : "scope_parameter_list" })).append(pathCel);

        var textareaCel = $("<td>").append($("<textarea>", { id : 'workflow_def_filecontent', width : "100%", height : "100%" }));
        $(textareaCel).css('height', '250px');
        var thirdLine   = $("<tr>").append(textareaCel);

        $(mod).append(firstLine).append(secondLine).append(thirdLine);

        var loremipsum  = "Insert in the text box bellow the content of the SCO workflow file. On the left you have the name of the automatic parameters available for the scope you selected, 'node' or 'service provider'. Insert the text you want, and parameters surrounded by \[\% \%\] markups, like [% ou_from %]. You can also enter specific parameters that will be asked for definition while associating the workflow to a rule.";

        var expls       = $("<td>", { colspan : 2, text : loremipsum }).appendTo($("<tr>"));
        $(expls).addClass('helpCell').prependTo(mod);

        form.appendTo("body");
        form.dialog({
            width           : 600,
            modal           : true,
            resizable       : false,
            closeOnEscape   : false,
            title           : 'Create a Workflow Definition',
            close           : function() { $(this).remove(); },
            buttons         : {
                'Cancel'    : function() { $(this).dialog("close"); },
                'Ok'        : function() { $(form).formwizard("next"); }
            }
        }).parents("div.ui-dialog").find("a.ui-dialog-titlebar-close").remove();
        $(select).change();
        $(form).formwizard({
            disableUIStyles     : true,
            formPluginEnabled   : true,
            formOptions         : {
                beforeSubmit    : function(data) {
                    var pk      = data.pk;
                    var params  = {
                        workflow_name   : $('input#workflow_def_name').val(),
                        params          : {
                            internal    : {
                                scope_id    : $('select#param_preset_id').val(),
                                output_dir  : $('input#directoryinput').val(),
                            },
                            data        : {
                                template_content  : $('textarea#workflow_def_filecontent').val()
                            }
                        }
                    };
                    $.ajax({
                        url         : '/api/entity/' + managerid + "/createWorkflow",
                        type        : 'POST',
                        contentType : 'application/json',
                        data        : JSON.stringify(params),
                        complete    : function(a, status, c) {
                            if (status === 'success') {
                                $(form).dialog('close');
                                $(dial).dialog('close');
                                workflowdetails(wfid, wf);
                            }
                        }
                    });
                    return false;
                }
            }
        });

    }

    $(button).bind('click', createModal).appendTo(container);
}

function deleteWorkflowDef(workflowdef_id) {
    $.ajax({
        url     : '/api/workflowdef/' + workflowdef_id,
        type    : 'get',
        success : function(data) {
            var parampresetid   = data.param_preset_id;
            $.ajax({
                url     : '/api/workflowdef/' + workflowdef_id,
                type    : 'delete'
            });
            $.ajax({
                url     : '/api/parampreset/' + parampresetid,
                type    : 'delete'
            });
            $.ajax({
                url     : '/api/parampreset?relation=' + parampresetid,
                type    : 'get',
                success : function(data) {
                    $(data).each(function() {
                        $.ajax({
                            url     : '/api/parampreset/' + $(this).pk,
                            type    : 'delete'
                        });
                    });
                }
            });
        }
    });
}

function sco_workflow(container_id) {
    var container       = $("#" + container_id);
    var connectorTypeId;
    $.ajax({
        type        : 'POST',
        url         : '/api/serviceprovider/1/findManager',
        contentType : 'application/json',
        data        : JSON.stringify({ 'category' : 'WorkflowManager' }),
        success     : function(data) {
            var workflowmanagers    = data;
            for (var i in workflowmanagers) if (workflowmanagers.hasOwnProperty(i)) {
                $.ajax({
                    url     : '/api/serviceprovider/' + workflowmanagers[i].service_provider_id,
                    type    : 'GET',
                    async   : false,
                    success : function(data) {
                        workflowmanagers[i].service_provider    = data;
                        for (var prop in data) if (data.hasOwnProperty(prop)) {
                            if ((new RegExp("_name$")).test(prop)) {
                                workflowmanagers[i].service_provider_name = data[prop];
                            }
                        }
                    }
                });
            }
            create_grid({
                grid_id                 : 'workflowmanagement',
                content_container_id    : container_id,
                colNames                : [ 'Id', 'Service', 'Name' ],
                colModel                : [
                    { name : 'id', index : 'id', width : 60, sorttype : 'int' },
                    { name : 'service_provider_name', index : 'service_provider_name'},
                    { name : 'name', index : 'name' },
                ],
                data                    : workflowmanagers,
            });
        }
    });
    $(container).append(createWorkflowRuleAssociationButton())
}

function workflowdetails(workflowmanagerid, workflowmanager) {
    var dial    = $("<div>", {
        id      : "workflowmanagerdetailsdialog",
        width   : "600px"
    }).appendTo($('body'));
    $(dial).dialog({
        close       : function() { $(this).remove(); },
        width       : 626,
        resizable   : false,
        modal       : true,
        title       : workflowmanager.service_provider_name + ' - ' + workflowmanager.name
    });
    $.ajax({
        url         : '/api/entity/' + workflowmanager.id + '/getWorkflowDefs',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ no_associate : 1 }),
        success     : function(workflows) {
            create_grid({
                grid_id                 : 'workflowdefsgrid',
                content_container_id    : 'workflowmanagerdetailsdialog',
                colNames                : [ 'Id', 'Name' ],
                colModel                : [
                    { name : 'pk', index : 'pk', width : 30, sorttype : 'int' },
                    { name : 'workflow_def_name', index : 'workflow_def_name' }
                ],
                data                    : workflows,
            });
            $(dial).dialog("option", "position", $(dial).dialog("option", "position"));
            createSCOWorkflowDefButton(dial, workflowmanager.id, dial, workflowmanagerid, workflowmanager);
        }
    });
}

function workflowRuleConfigure(wfdef_id) {
    var dial    = $("<div>");
    var form    = $("<table>", { width : '100%' }).appendTo($("<form>").appendTo(dial));
    var param_preset;

    function    validateTheForm() {
        var specparamsinputs    = $("input.input_specific_param");
        $(specparamsinputs).each(function() {
            param_preset.specific[$(this).attr('name')] = getRawValue($(this).val(), 'unit_' + $(this).attr('name'));
        });
        $.ajax({
            url         : '/api/workflowdef/' + wfdef_id + '/updateParamPreset',
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify({params : param_preset}),
            success     : function() {
                  $(dial).dialog('close');
            }
        });
    }

    $.ajax({
        type    :'POST',
        url     : 'api/workflowdef/' + wfdef_id + '/getParamPreset',
        success : function(data) {
            param_preset = data;
            if (data.specific === null) {
                alert('This workflow has no parameter');
                return;
            }
            $.get(
                    'api/workflowdef/' + wfdef_id + '/workflow_def_origin',
                    function(wf_origin) {
                        $.post(
                                'api/workflowdef/' + wf_origin.pk + '/getParamPreset',
                                function (origin_params) {
                                    $.each(data.specific, function(k,v) {
                                        var field_info  = origin_params.specific[k];
                                        var line        = $("<tr>").appendTo(form);
                                        $(line).append($("<td>").append($("<label>", {
                                            for     : 'input_specific_param_' + k,
                                            text    : (field_info ? field_info.label : k) + ' : '
                                        })));
                                        var value = v;
                                        var selected_unit;
                                        if (field_info && field_info.unit && field_info.unit == 'byte') {
                                            var prefix = value.substr(0,1);
                                            if (prefix == '+' || prefix == '-') {
                                                value = value.substr(1);
                                            } else {
                                                prefix = '';
                                            }
                                            var readable_value = getReadableSize(value);
                                            value           = prefix + readable_value.value;
                                            selected_unit   = readable_value.unit;
                                        }
                                        $(line).append($("<td>", { align : "right" }).append($("<input>", {
                                            type    : 'test',
                                            name    : k,
                                            value   : value,
                                            id      : 'input_specific_param_' + k,
                                            class   : 'input_specific_param'
                                        })));
                                        var unit_cont = $('<td>');
                                        $(line).append(unit_cont);
                                        addFieldUnit(origin_params.specific[k], unit_cont, 'unit_' + k, selected_unit);
                                    });

                                    $(dial).dialog({
                                        resizable       : false,
                                        closeOnEscape   : false,
                                        modal           : true,
                                        width           : '400px',
                                        close           : function() { $(this).remove(); },
                                        buttons         : {
                                            'Cancel'    : function() { $(this).dialog('close'); },
                                            'Ok'        : validateTheForm
                                        }
                                    });
                                }
                        );
                    }
            );
        }
    });

}

function workflowRuleAssociation(eid, scid, cid, serviceprovider_id) {
    var dial    = $("<div>");
    var form    = $("<table>", { width : '100%' }).appendTo($("<form>").appendTo(dial));
    var wfdefs  = [];
    var manager;

    function createForm(event) {
        var wfdefid     = $(event.currentTarget).val();
        for (var i in wfdefs) if (wfdefs.hasOwnProperty(i)) {
            if (wfdefs[i].pk === wfdefid) {
                var wfdef       = wfdefs[i];
                var specparams  = wfdefs[i].specificparams;
                $(form).empty();
                $(form).append($("<input>", {
                    type    : 'hidden',
                    name    : 'origin_workflow_name',
                    id      : 'input_origin_workflow_name',
                    value   : wfdef.workflow_def_name
                }));
                $(form).append($("<input>", {
                    type    : 'hidden',
                    name    : 'origin_workflow_id',
                    id      : 'input_origin_workflow_id',
                    value   : wfdef.workflow_def_id
                }));
                for (var j in specparams) if (specparams.hasOwnProperty(j)) {
                    var line    = $("<tr>").appendTo(form);
                    $(line).append($("<td>").append($("<label>", {
                        for     : 'input_specific_param_' + j,
                        text    : (specparams[j] ? specparams[j].label : j) + ' : '
                    })));
                    $(line).append($("<td>", { align : "right" }).append($("<input>", {
                        type    : 'test',
                        name    : j,
                        id      : 'input_specific_param_' + j,
                        class   : 'input_specific_param'
                    })));
                    var unit_cont = $('<td>');
                    $(line).append(unit_cont);
                    addFieldUnit(specparams[j], unit_cont, 'unit_' + j, 'MB');
                }
                break;
            }
        }
    }

    function validateTheForm() {
        var params              = {
            new_workflow_name       : eid + '_' + $("input#input_origin_workflow_name").val(),
            origin_workflow_def_id  : $("input#input_origin_workflow_id").val(),
            specific_params         : {},
            rule_id                 : eid
        };
        var specparamsinputs    = $("input.input_specific_param");
        $(specparamsinputs).each(function() {
            params.specific_params[$(this).attr('name')] = getRawValue($(this).val(), 'unit_' + $(this).attr('name'));
        });
        $.ajax({
            url         : '/api/entity/' + manager.pk + '/associateWorkflow',
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify(params),
            complete    : function(a) {
                if (a.status === 200) {
                    $(dial).dialog('close');
                    reload_content(cid, eid);
                }
            }
        });
    }

    $.ajax({
        url         : '/api/serviceprovider/' + serviceprovider_id + '/getManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'manager_type' : 'workflow_manager' }),
        success     : function(data) {
            // TODO call getWorkflowDefs instead of getWorkflowDefsIds to avoid all /api/workflowdef/<id> requests
            // TODO call getWorkflowDefs with data { no_associate : 1 } to avoid workflow filtering in client side
            manager = data;
            $.ajax({
                url         : '/api/entity/' + manager.pk + '/getWorkflowDefsIds',
                type        : 'POST',
                contentType : 'application/json',
                data        : JSON.stringify({}),
                success     : function(data) {
                    var ok  = false;
                    if (data.length <= 0) {
                        alert('No workflow definition found.');
                    } else {
                        var select  = $('<select>').prependTo(dial);
                        $(select).bind('change', createForm);
                        for (var i in data) if (data.hasOwnProperty(i)) {
                            $.ajax({
                                url     : '/api/workflowdef/' + data[i],
                                type    : 'GET',
                                success : function(wfd) {
                                    $.ajax({
                                        url         : '/api/entity/' + manager.pk + '/_getAllParams',
                                        type        : 'POST',
                                        contentType : 'application/json',
                                        data        : JSON.stringify({ 'workflow_def_id' : wfd.pk }),
                                        success     : function(dat) {
                                            if ((dat.internal.association == null || dat.internal.association == false)
                                                && dat.internal.scope_id == scid) {
                                                if (!ok) ok = true;
                                                wfd.specificparams  = dat.specific;
                                                wfdefs.push(wfd);
                                                $(select).append($("<option>", { text : wfd.workflow_def_name, value : wfd.pk }));
                                                $(select).change();
                                            }
                                            if (ok === false && (i + 1) == data.length) {
                                                $(dial).dialog('close');
                                                alert('No workflow definition found.');
                                            }
                                        }
                                    });
                                }
                            });
                        }
                        $(dial).dialog({
                            resizable       : false,
                            closeOnEscape   : false,
                            modal           : true,
                            width           : '400px',
                            close           : function() { $(this).remove(); },
                            buttons         : {
                                'Cancel'    : function() { $(this).dialog('close'); },
                                'Ok'        : validateTheForm
                            }
                        });
                    }
                }
            });
        },
        error       : function() {
            alert("No workflow manager found.");
        }
    });
}

function workflowRuleDeassociation(cid, rule_id, wfdef_id, serviceprovider_id) {
    $.ajax({
        url         : '/api/serviceprovider/' + serviceprovider_id + '/getManager',
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify({ 'manager_type' : 'workflow_manager' }),
        success     : function(manager) {
            var params = {
                    workflow_def_id : wfdef_id,
                    rule_id         : rule_id
            };
            $.ajax({
                url         : '/api/entity/' + manager.pk + '/deassociateWorkflow',
                type        : 'POST',
                contentType : 'application/json',
                data        : JSON.stringify(params),
                success    : function(a) {
                        reload_content(cid, rule_id);
                }
            });
        }
    });
}

function createWorkflowRuleAssociationButton(cid, eid, scid, serviceprovider_id) {
    var button  = $("<a>", { text : 'Associate a Workflow' }).button();
    button.bind('click', function() { workflowRuleAssociation(eid, scid, cid, serviceprovider_id); });
    $('#' + cid).append(button);
}

function appendWorkflowActionsButtons(elem, cid, rule_id, wfdef_id, serviceprovider_id) {
    $(elem).append($("<a>", { text : 'Configure', style : 'margin-left: 15px;' }).button({ icons : { primary : 'ui-icon-wrench' } })
                .bind('click', function(event) {workflowRuleConfigure(wfdef_id)}));
    $(elem).append($("<a>", { text : 'Deassociate', style : 'margin-left: 15px;' }).button({ icons : { primary : 'ui-icon-trash' } })
                .bind('click', function(event) {workflowRuleDeassociation(cid, rule_id, wfdef_id, serviceprovider_id)}));
}

function workflowslist(cid, eid) {
    $.ajax({
        url     : '/api/serviceprovider/' + eid + '/getWorkflows',
        type    : 'POST',
        success : function(data) {
            for (var i in data) if (data.hasOwnProperty(i)) {
                data[i].currentOperation    = 'Loading...';
            }
            create_grid({
                content_container_id    : cid,
                grid_id                 : 'workflowsgrid',
                action_delete           : { url : '/api/workflow', method: 'cancel' },
                data                    : data,
                colNames                : [ 'Id', 'Name', 'State', 'Current Operation' ],
                afterInsertRow          : function(grid, rowid, rowdata, rowelem) {
                    $.ajax({
                        url     : '/api/workflow/' + rowdata.pk + '/getCurrentOperation',
                        type    : 'POST',
                        success : function(data) {
                            rowelem.currentOperation    = data.type;
                            $(grid).setCell(rowid, 'currentOperation', rowelem.currentOperation);
                        }
                    });
                },
                colModel                : [
                    { name : 'pk', index : 'pk', sorttype : 'int', hidden : true, key : true },
                    { name : 'workflow_name', index : 'workflow_name' },
                    { name : 'state', index : 'state' },
                    { name : 'currentOperation', index : 'currentOperation' }
                ]
            });
        }
    });
}

function runningworkflowslist(cid, eid) {
    create_grid({
        url                  : '/api/workflow?state=running&entity_id='+eid,   
        caption              : 'Running workflows',
        content_container_id : cid,
        grid_id              : 'runningworkflowsgrid',
        action_delete        : { url : '/api/workflow', method: 'cancel' },
        colNames             : [ 'Id', 'Name', 'Current Operation', 'Step' ],
        afterInsertRow       : function(grid, rowid, rowdata, rowelem) {
            $.ajax({
                url     : '/api/workflow/' + rowdata.pk + '/getCurrentOperation',
                type    : 'POST',
                success : function(data) {
                    rowelem.currentOperation    = data.type;
                    $(grid).setCell(rowid, 'currentOperation', rowelem.currentOperation);
                }
            });
        },
        colModel                : [
            { name : 'pk', index : 'pk', sorttype : 'int', hidden : true, key : true },
            { name : 'workflow_name', index : 'workflow_name' },
            { name : 'currentOperation', index : 'currentOperation' },
            { name : 'step', index : 'step' }
        ]
    });
    $('<br />').appendTo('#'+cid);
}

function historicworkflowslist(cid, eid) {
    create_grid({
        url                     : '/api/workflow?state=<>,running&entity_id='+eid,   
        caption                 : 'History',
        content_container_id    : cid,
        grid_id                 : 'historicworkflowsgrid',
        action_delete           : 'no',
        colNames                : [ 'Id', 'Name', 'State' ],
        colModel                : [
            { name : 'pk', index : 'pk', sorttype : 'int', hidden : true, key : true },
            { name : 'workflow_name', index : 'workflow_name', width: 10 },
            { name : 'state', index : 'state', width: 10 }
        ],
        details                 : { onSelectRow : function(wid) {
                                                    var url = "/workflows/"+wid+"/log";
                                                    window.open(url, "workflow log", "menubar=no, status=no, width=640, height=800,");
        }}
    });
}

function workflowsoverview(cid, eid) {
  create_grid({
        url                     : '/api/workflow',
        grid_id                 : 'workflowslistgrid',
        content_container_id    : cid,
        colNames                : [ 'Id', 'Name', 'State', 'CurrentOperation' ],
        afterInsertRow          : function(grid, rowid, rowdata, rowelem) {
            if (rowdata.state != 'done') {
                $.ajax({
                    url     : '/api/workflow/' + rowdata.pk + '/getCurrentOperation',
                    type    : 'POST',
                    success : function(data) {
                        $(grid).setCell(rowid, 'currentOperation', data.type);
                    }
                });
            } else {
                $(grid).setCell(rowid, 'currentOperation', ' ');
            }
        },
        colModel                : [
            { name : 'pk', index : 'pk', sorttype : 'int', hidden : true, key : true },
            { name : 'workflow_name', index : 'workflow_name' },
            { name : 'state', index : 'state' },
            { name : 'currentOperation', index : 'currentOperation', formatter : function(a) { if (a == null) return 'Loading...'; else return a; } }
        ],
        sortname    : 'state',
        sortorder   : "desc"
  });
}
