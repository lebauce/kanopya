
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

    var scopes  = {};
    // Retrieve all Scopes
    $.ajax({
        url     : '/api/scope',
        type    : 'get',
        success : function(data) {
            // For each Scope, retrieve all ScopeParameters
            $(data).each(function(){
                var scope   = this;
                $.ajax({
                    url     : '/api/scope/' + scope.pk + '/scope_parameters',
                    type    : 'get',
                    success : function(data) {
                        scopes[scope.scope_name]  = data;
                    }
                });
            });
        }
    });

    function    createModal() {
        var form        = $("<form>", { id : "workflow_def_creation" });
        var mod         = $("<table>", { width : "100%" }).appendTo(form);

        function    changeScopeParametersList(event) {
            var value   = event.currentTarget.value;
            var cont    = $("td#scope_parameter_list");
            $(cont).empty().append(createParameterList(scopes[value]));
        }

        var select      = $("<select>");
        for (i in scopes) if (scopes.hasOwnProperty(i)) {
            $(select).append($("<option>", { text : i }));
        }
        $(select).bind('change', changeScopeParametersList);

        var textareaCel = $("<td>", { rowspan : "2" }).append($("<textarea>", { width : "100%", height : "100%" }));
        $(textareaCel).css('height', '250px');

        var firstLine   = $("<tr>");
        $(firstLine).append($("<td>").attr('width', '150').attr('height', '20').append(select)).append(textareaCel);
        var secondLine  = $("<tr>").append($("<td>", { id : "scope_parameter_list" }));
        $(mod).append(firstLine).append(secondLine);

        var loremipsum  = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis in mauris ante. Mauris arcu felis, aliquet pellentesque ornare vitae, congue non purus. Nullam nunc orci, ultrices vitae porta non, consequat in lacus. Nunc ut rutrum felis. Cras suscipit lectus mauris. Duis et dictum quam. Vestibulum lacus elit, commodo tincidunt dignissim vel, eleifend quis purus. Nunc sit amet dignissim sem.";

        var expls       = $("<td>", { colspan : 2, text : loremipsum }).appendTo($("<tr>"));
//        $(expls).addClass('helpCell').prependTo(mod);

        form.appendTo("body");
        form.dialog({
            width           : 600,
            modal           : true,
            draggable       : false,
            resizable       : false,
            closeOnEscape   : false,
            title           : 'Create a Workflow Definition',
            buttons         : {
                'Cancel'    : function() {
                    $(this).dialog("destroy");
                },
                'Ok'        : function() {
                    $(this).dialog("destroy");
                }
            }
        }).parents("div.ui-dialog").find("a.ui-dialog-titlebar-close").remove();
        $(select).change();

    }

    $(button).bind('click', createModal).appendTo(container);
}

function    sco_workflow(container_id) {
    var container   = $("#" + container_id);
    createSCOWorkflowDefButton(container);
}