// This file is used to check and display notifications about new messages.
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
                    //var content = rows[row].message_content;
                    // Get message level :
                    var content = "From : " + rows[row].message_from + " <br /> " + rows[row].message_content;
                    newMsg = true;
                    // Display the notification :
                    $.gritter.add({
                        title: 'Message',
                        text: content,
                    });
                    if (parseInt(rows[row].pk) > maxID) {maxID = parseInt(rows[row].pk)}
                }
            });
            if (newMsg === true) {
                $("#grid-message").trigger('reloadGrid');
            }
            lastMsgId = maxID;
         }
    });

    var workflows = get("/api/workflow?state=pending");
    workflows = workflows.concat(get("/api/workflow?state=running"));

    for (var i = 0; i < workflows.length; i++) {
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
    
}, 5000);
