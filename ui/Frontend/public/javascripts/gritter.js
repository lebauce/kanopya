// This file is used to check and display notifications about new messages.

function get(url) {
    var value;
    $.ajax({
        url     : url,
        async   : false,
        success : function(data) { value = data; }
    });

    return value;
}

function callMethod(options) {
    $.ajax({
        url: options.url,
        type: "POST",
        data: options.data || { },
        success: function (data) {
            $.gritter.add({
                title: 'Message',
                text: content
            });
            if (options.success) {
                options.success(data);
            }
        }
    });
}

function formatOperations(operations) {
    var ul = $("<ul class='gritter-operations'></ul>");
    for (var i = 0; i < operations.length; i++) {
        var operation = operations[i];
        var state;
        if (operation.state == "running" || operation.state == "ready" ||
            operation.state == "processing" || operation.state == "prereported" ||
            operation.state == "postreported") {
            state = $("<div class='ui-icon icon-running'>");
        }
        else if (operation.state == "done" || operation.state == "succeeded") {
            state = $("<div class='ui-icon icon-done'></div>");
        }
        else if (operation.state == "pending") {
            state = $("<div class='ui-icon ui-icon-radio-on'></div>");
        }
        else {
            state = operation.state;
        }

        var label = operation.type;
        if (operation.label != undefined) {
            label = operation.label;
        }

        ul.append($("<li></li>")
                       .append(
                           $("<div>" + label + "</div>")
                               .addClass("operation_type")
                       )
                       .append(
                           $("<div></div>")
                               .addClass("operation_state")
                               .append(state)
                       )
                  );
    };

    return ul;
}

function updateWorkflowGritter(workflow) {
    var gritter = $('.gritter-item-workflow-' + workflow.pk);
    var gritterId = gritter[0].id.substr(13);
    var id = workflow.pk;
    var ul = gritter.find("ul.gritter-operations");
    var operations = get("/api/operation?workflow_id=" + id  + "&order_by=execution_rank");
    ul.empty().append(formatOperations(operations).children());

    if (workflow.state != "running" && workflow.state != "pending") {
        $.gritter.remove(gritterId);
        return;
    }
}

function showWorkflowGritter(workflow) {
    var operations = get("/api/operation?workflow_id=" + workflow.pk + "&order_by=execution_rank");
    var title =  "" + workflow.workflow_name;
    var content = $("<div></div>");
    var trigger = workflow.rule ? ("rule \"" + workflow.rule.label + "\"") : workflow.user;

    var ul = formatOperations(operations);
    if (operations.length == 0) {
        return;
    }
    content.append(ul);
    var gritterId = $.gritter.add({
        title : "<span class='workflow-name'>" + title + "</span>" +
                "<div class='gritter-action'>" +
                    "<div title='Cancel workflow' class='ui-icon icon-cancel'></div>" +
                "</div><br>" +
                "<span class='workflow-owner'>(trigerred by " + trigger + ")</span>",
        text: content.html(),
        sticky: true
    });
    var gritter = $('#gritter-item-' + gritterId);
    gritter.find(".gritter-action").click(function () {
        callMethod({
            url: "/api/workflow/" + workflow.pk + "/cancel",
            success: function (data) { $.gritter.remove(gritterworkflow.pk); }
        });
    });
    gritter.addClass("gritter-item-workflow-" + workflow.pk);
    gritter.addClass("gritter-item-workflow");
    gritter.data("workflow", workflow.pk);
}

// Check if there is new messages and running workflows
// Update messages grid if necessary
// Display gritters for messages and workflows if option show_gritters is set
function updateMessages( show_gritters ) {
    var jsondata = '';
    var maxID = lastMsgId;
    // Get Messages
    $.ajax({
        url: '/api/message?rows=100&order_by=message_id%20DESC',
        success: function(rows) {
            var newMsg = false;
            $(rows).each(function(row) {
                // Get the ID of last emmited message :
                if ( rows[row].pk > lastMsgId ) {
                    var sender = rows[row].message_from;
                    var lvl = rows[row].message_level;
                    //var content = rows[row].message_content;
                    newMsg = true;
                    // Check sender (if sender is Executor and level is Inof, do not display the gritter) :
                    if ( show_gritters && (sender != "Executor" || lvl != "info") ) {
                        var content = rows[row].message_content;
                        // Clean message for user by removing first part of content (class name and address). And add icon.
                        var formatted_content = content.replace(/\[.*\]\s/, '');
                        formatted_content = '<div class="message-'+lvl+' message-level" style="float:left"/>' + escapeHtmlEntities(formatted_content);
                        // Display the notification :
                        $.gritter.add({
                            title: ' ',
                            text  : formatted_content,
                        });
                    }
                    if (parseInt(rows[row].pk) > maxID) {
                        maxID = parseInt(rows[row].pk)
                    }
                }
            });
            if (newMsg === true) {
                $("#grid-message").trigger('reloadGrid');
            }
            lastMsgId = maxID;
         }
    });

    if (!show_gritters) {
        return;
    }

    $.getJSON("/api/workflow?state=pending&rows=5", function (pending) {
        $.getJSON("/api/workflow?state=running&rows=5", function (running) {
            var workflows = pending.concat(running);
            for (var i = 0; i < workflows.length; i++) if (workflows.hasOwnProperty(i) && workflows[i] != null) {
                var gritter = $('.gritter-item-workflow-' + workflows[i].pk);
                if (gritter.length) {
                    updateWorkflowGritter(workflows[i]);
                } else {
                    try {
                        // Try to get the workflow to check permissions
                        // Display the popup
                        showWorkflowGritter(get("/api/workflow/" + workflows[i].pk + "?expand=rule"));
                    }
                    catch (e) {
                        console.log(e);
                    }
                }
            }

            $.each($(".gritter-item-workflow"), function (n, gritter) {
                var displayed = false;
                var id = $(gritter).data("workflow");
                for (var i = 0; i < workflows.length; i++) {
                    if (workflows[i].pk == id) {
                        displayed = true;
                        break;
                    }
                }
                if (!displayed) {
                    try {
                       updateWorkflowGritter(get("/api/workflow/" + id));
                    }
                    catch (e) {
                        console.log(e);
                    }
                }
            });
        });
    });

}

$(document).ready(function () {
    $.get('/conf', function (conf) {
            window.setInterval( function() {
                updateMessages( conf.show_gritters )
            }, conf.messages_update * 1000);
    });
});
