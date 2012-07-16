

function get(url) {
    var json;

    $.ajax({
        url: url,
        async: false,
        success: function (data) {
            json = data;
        }
    });

    return json;
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
        if (operation.state == "running") {
            state = $("<img src='/images/icons/ajax-loader.gif'>");
        }
        else if (operation.state == "done") {
            state = $("<div class='ui-icon ui-icon-check'></div>");
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
                    "<div class='ui-icon ui-icon-radio-on'></div>" +
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

function loadServicesDetails(cid, eid) {
        
    var divId = 'service_details';
    var container = $('#'+ cid);
    var table       = $("<tr>").appendTo($("<table>").css('width', '100%').appendTo(container));
    var div = $('<div>', { id: divId}).appendTo($("<td>").appendTo(table));
     $('<h4>Details</h4>').appendTo(div);
        
    var service_opts = {
        name   : 'cluster',
        filters : { expand : 'kernel,masterimage,user,service_template' },
        fields : { cluster_name         : {label: 'Name'},
                   cluster_state        : {label: 'State'},
                   cluster_prev_state   : {label: 'Previous state'},
                   active               : {label: 'Active'},
                   cluster_min_node     : {label: 'Min node'},
                   cluster_max_node     : {label: 'Max node'},
                   "masterimage.masterimage_name" : {label: 'Master Image'},
                   "kernel.kernel_name" : {label: 'Kernel'},
                   "service_template.service_name" : {label: 'Service template'},
                   cluster_domainname   : {label: 'Domain name'},
                   cluster_nameserver1  : {label: 'Domain name server 1'},
                   cluster_nameserver2  : {label: 'Domain name server 2'},
                   cluster_boot_policy  : {label: 'Boot policy'},
                   cluster_basehostname : {label: 'Base hostname'},
                   cluster_priority     : {label: 'Priority'},
                   cluster_si_persistent: {label: 'Persistent'},
                   cluster_si_shared    : {label: 'Shared'},
                   "user.user_login"    : {label: 'User'},
                                            

        },
    };   

    var details = new DetailsTable(divId, eid, service_opts);

    details.show();
 
    var actioncell  = $('<td>').css('text-align', 'right').appendTo(table);
    $(actioncell).append($('<div>').append($('<h4>', { text : 'Actions' })));
    $.ajax({
        url     : '/api/serviceprovider/' + eid,
        success : function(data) {
            var buttons     = [
                {
                    label       : 'Start service',
                    icon        : 'play',
                    action      : '/api/cluster/' + eid + '/start',
                    condition   : (new RegExp('^down')).test(data.cluster_state)
                },
                {
                    label       : 'Stop service',
                    icon        : 'stop',
                    action      : '/api/cluster/' + eid + '/stop',
                    condition   : (new RegExp('^up')).test(data.cluster_state)
                },
                {
                    label       : 'Force stop service',
                    icon        : 'stop',
                    action      : '/api/cluster/' + eid + '/forceStop',
                    condition   : (!(new RegExp('^down')).test(data.cluster_state))
                },
                {
                    label       : 'Scale out',
                    icon        : 'arrowthick-2-e-w',
                    action      : '/api/cluster/' + eid + '/addNode'
                }
            ];
            createallbuttons(buttons, actioncell);
        }
    });
}

function createallbuttons(buttons, container) {
    for (var i in buttons) if (buttons.hasOwnProperty(i)) {
        if (buttons[i].condition === undefined || buttons[i].condition) {
            $(container).append(createbutton(buttons[i]));
            $(container).append($('<br />'));
        }
    }
}

function createbutton(button) {
    return $('<a>', { text : button.label }).button({
        icons : { primary : 'ui-icon-' + button.icon }
    }).bind('click', ((typeof(button.action) === 'string') ? function() {
        $.ajax({
            url         : button.action,
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify((button.data !== undefined) ? button.data : {})
        });
    } : button.action));
}
