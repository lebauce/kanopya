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

        ul.append($("<li></li>")
                       .append(
                           $("<div>" + operation.type + "</div>")
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
    var operations = get("/api/workflow/" + id + "/operations");
    ul.empty().append(formatOperations(operations).children());
    if (workflow.state != "running" && workflow.state != "pending") {
        $.gritter.remove(gritterId);
        return;
    }
}

function showWorkflowGritter(workflow) {
    var id = workflow.pk;
    var operations = get("/api/workflow/" + id + "/operations");
    var title = "Running workflow '" + workflow.workflow_name + "'";
    var content = $("<div></div>");
    var ul = formatOperations(operations);
    if (operations.length == 0) {
        return;
    }
    content.append(ul);
    var gritterId = $.gritter.add({
        title : "<div>" + title + "</div>" +
                "<div class='gritter-action'>" +
                    "<div title='Cancel workflow' class='ui-icon icon-cancel'></div>" +
                "</div>",
        text: content.html(),
        sticky: true
    });
    var gritter = $('#gritter-item-' + gritterId);
    gritter.find(".gritter-action").click(function () {
        callMethod({
            url: "/api/workflow/" + id + "/cancel",
            success: function (data) { $.gritter.remove(gritterId); }
        });
    });
    gritter.addClass("gritter-item-workflow-" + id);
    gritter.addClass("gritter-item-workflow");
    gritter.data("workflow", id);
}

window.setInterval(function(){

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
                    // Check sender (if sender is Executor and level is Inof, do not display the gritter) :
                    if ( sender == "Executor" && lvl == "info") {
                        
                    } else {
                        // Get message level :
                        var content = "From : " + rows[row].message_from + " <br /> " + "Level : " + rows[row].message_level + " <br /> " + rows[row].message_content;
                        newMsg = true;
                        // Display the notification :
                        $.gritter.add({
                            title: 'Message',
                            text: content,
                        });
                        if (parseInt(rows[row].pk) > maxID) {
                            maxID = parseInt(rows[row].pk)
                        }
                    }
                }
            });
            if (newMsg === true) {
                $("#grid-message").trigger('reloadGrid');
            }
            lastMsgId = maxID;
         }
    });

    $.getJSON("/api/workflow?state=pending", function (pending) {
        $.getJSON("/api/workflow?state=running", function (running) {
            var workflows = pending.concat(running);
            for (var i = 0; i < workflows.length; i++) if (workflows.hasOwnProperty(i) && workflows[i] != null) {
                var gritter = $('.gritter-item-workflow-' + workflows[i].pk);
                if (gritter.length) {
                    updateWorkflowGritter(workflows[i]);
                } else {
                    showWorkflowGritter(workflows[i]);
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
                    var workflow = get("/api/workflow/" + id);
                    updateWorkflowGritter(workflow);
                }
            });
        });
    });

}, 10000);
