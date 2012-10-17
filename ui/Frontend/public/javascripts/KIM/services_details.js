function loadServicesDetails(cid, eid) {
        
    var divId = 'service_details';
    var container = $('#'+ cid);
    var table       = $("<tr>").appendTo($("<table>").css('width', '100%').appendTo(container));
    var div = $('<div>', { id: divId}).appendTo($("<td>").appendTo(table));
     $('<h4>Details</h4>').appendTo(div);

    //VMware Browser Tree
    require('KIM/vmware.js');
    $('<button>',{html:'Browse VMware'}).click(vmwareBrowser).appendTo(container);

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
    
    $('<h4>', { text : 'Managers' }).appendTo(div);
    var managerstable   = $('<table>').appendTo(div);

    $.ajax({
        url     : '/api/serviceprovider/' + eid + '/getManagers',
        type    : 'POST',
        success : function(data) {
            for (var i in data) if (data.hasOwnProperty(i)) {
                var tr  = $('<tr>').appendTo(managerstable);

                // Ugly test to handle both managers type component/connector
                if (data[i].component_type_id) {
                    $.ajax({
                        url     : '/api/componenttype/' + data[i].component_type_id,
                        success : function(line) {
                            return (function(component_type) {
                                $(line).append($('<th>', { text : component_type.component_category + ' : ' }))
                                       .append($('<td>', { text : component_type.component_name }));
                            });
                        }(tr)
                    });
                } else {
                    $.ajax({
                        url     : '/api/connectortype/' + data[i].connector_type_id,
                        success : function(line) {
                            return (function(connector_type) {
                                $(line).append($('<th>', { text : connector_type.connector_category + ' : ' }))
                                       .append($('<td>', { text : connector_type.connector_name }));
                            });
                        }(tr)
                    });

                }
            }
        }
    });

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
