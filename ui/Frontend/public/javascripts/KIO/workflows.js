
function    createSCOWorkflowDefButton(container) {

    function    createParameterList(parameters) {
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
    var button  = $("<button>", { text : "Create a Workflow definition" });

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

    function    createModal() {
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

        var loremipsum  = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis in mauris ante. Mauris arcu felis, aliquet pellentesque ornare vitae, congue non purus. Nullam nunc orci, ultrices vitae porta non, consequat in lacus. Nunc ut rutrum felis. Cras suscipit lectus mauris. Duis et dictum quam. Vestibulum lacus elit, commodo tincidunt dignissim vel, eleifend quis purus. Nunc sit amet dignissim sem.";

        var expls       = $("<td>", { colspan : 2, text : loremipsum }).appendTo($("<tr>"));
        $(expls).addClass('helpCell').prependTo(mod);

        form.appendTo("body");
        form.dialog({
            width           : 600,
            modal           : true,
            draggable       : false,
            resizable       : false,
            closeOnEscape   : false,
            title           : 'Create a Workflow Definition',
            buttons         : {
                'Cancel'    : function() { $(this).dialog("destroy"); },
                'Ok'        : function() { $(form).formwizard("next"); }
            }
        }).parents("div.ui-dialog").find("a.ui-dialog-titlebar-close").remove();
        $(select).change();
        $(form).formwizard({
            disableUIStyles     : true,
            formPluginEnabled   : true,
            formOptions         : {
                success         : function(data) {
                    var pk      = data.pk;
                    var params  = {
                        params  : {
                            scope_id    : $('select#param_preset_id').attr('value'),
                            output_dir  : $('input#directoryinput').attr('value')
                        }
                    };
                    $.ajax({
                        url         : '/api/workflowdef/' + pk + "/setParamPreset",
                        type        : 'post',
                        contentType : 'application/json',
                        data        : JSON.stringify(params),
                        complete    : function(a, status, c) {
                            if (status === 'error') {
                                deleteWorkflowDef(pk);
                            } else {
                            }
                        }
                    });
                }
            }
        });

    }

    $(button).bind('click', createModal).appendTo(container);
}

function    deleteWorkflowDef(workflowdef_id) {
    $.ajax({
        url     : '/api/workflowdef/' + workflowdef_id,
        type    : 'delete'
    });
}

function    sco_workflow(container_id) {
    var container   = $("#" + container_id);
    createSCOWorkflowDefButton(container);
}