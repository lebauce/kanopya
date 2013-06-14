require('common/general.js');

function loadServicesDetails(cid, eid, is_iaas) {
        
    var divId = 'service_details';
    var container = $('#'+ cid);
    if (container.prevAll('.action_buttons').length === 0) {
        container.before('<div class="action_buttons"></div>');
    }
    var table       = $("<tr>").appendTo($("<table>").css('width', '100%').appendTo(container));
    var div = $('<div>', { id: divId}).appendTo($("<td>").appendTo(table));
     $('<h4>Details</h4>').appendTo(div);

    $("#" + divId).append(
        new KanopyaFormWizard({
            title      : 'Add components',
            type       : 'cluster',
            id         : eid,
            relations  : { },
            displayed  : [ 'cluster_name', 'cluster_state', 'active', 'cluster_min_node',
                           'cluster_max_node', 'masterimage_id', 'kernel_id', 'user_id',
                           'cluster_nameserver1', 'cluster_nameserver2', 'cluster_boot_policy',
                           'cluster_basehostname' ],
            rawattrdef : {
                components : {
                    hide_existing : 1
                }
            }
        }).content);

    $('<h4>', { text : 'Managers' }).appendTo(div);
    var managerstable   = $('<table>').appendTo(div);

    $.ajax({
        url     : '/api/serviceprovider/' + eid + '/service_provider_managers?expand=manager_category,manager.component_type',
        type    : 'GET',
        success : function(data) {
            for (var i in data) if (data.hasOwnProperty(i)) {
                var tr = $('<tr>').appendTo(managerstable);
                $(tr).append($('<th>', { text : data[i].manager_category.label + ' : ' }))
                     .append($('<td>', { text : data[i].manager.component_type.label }));
            }
        }
    });

    // If this sp is a Iaas, we get its cloud manager component id (used for optimiaas)
    var cloudmanager_id;
    if (is_iaas) {
        $.ajax({
                url     : '/api/component',
                data    : {
                    'service_provider_id'               : eid,
                    'component_type.component_type_categories.component_category.category_name' : 'HostManager'
                },
                async   : false,
                success : function(data) {
                    cloudmanager_id = data[0].pk;
                }
        });
    }

    //var actioncell  = $('<td>', {'class' : 'action-cell'}).css('text-align', 'right').appendTo(table);
    var actioncell=$('#' + cid).prevAll('.action_buttons'); 

    function scaleOutComponentsDialog (e) {
        // Get the component types list availabe on this service provider
        var components = ajax('GET', '/api/serviceprovider/' + eid + '/components?expand=component_type');
        var component_types = {};
        for (var index in components) {
            component_types[components[index].component_type.pk] = components[index].component_type.component_name;
        }

        // Open a wizards to suggest component type to scale to the user
        (new KanopyaFormWizard({
            title      : 'Scale out components',
            displayed  : [ 'component_types' ],
            rawattrdef : {
                component_types : {
                    label        : 'Components to scale out',
                    type         : 'relation',
                    relation     : 'multi',
                    is_mandatory : 1,
                    options      : component_types
                }
            },
            submitCallback  : function(data, $form, opts, onsuccess, onerror) {
                ajax('POST', '/api/cluster/' + eid + '/addNode', data, onsuccess, onerror);
            }
        })).start();

    }

    //$(actioncell).append($('<div>').append($('<h4>', { text : 'Actions' })));
    $.ajax({
        url     : '/api/serviceprovider/' + eid,
        success : function(data) {
            var buttons     = [
                {
                    label       : 'Start service',
                    sprite      : 'start',
                    action      : '/api/cluster/' + eid + '/start',
                    condition   : (new RegExp('^down')).test(data.cluster_state),
                    confirm     : 'This will start your instance'
                },
                {
                    label       : 'Stop service',
                    sprite      : 'stop',
                    action      : '/api/cluster/' + eid + '/stop',
                    condition   : (new RegExp('^up')).test(data.cluster_state),
                    confirm     : 'This will stop all your running instances'
                },
                {
                    label       : 'Force stop service',
                    sprite      : 'stop',
                    action      : '/api/cluster/' + eid + '/forceStop',
                    condition   : (!(new RegExp('^down')).test(data.cluster_state)),
                    confirm     : 'This will stop all your running instances'
                },
                {
                    label       : 'Scale out',
                    icon        : 'arrowthick-2-e-w',
                    action      : '/api/cluster/' + eid + '/addNode'
                },
                {
                    label       : 'Scale out components',
                    icon        : 'arrowthick-2-e-w',
                    action      : scaleOutComponentsDialog
                },
                {
                    label       : 'Optimize IaaS',
                    icon        : 'calculator',
                    action      : '/api/component/' + cloudmanager_id + '/optimiaas',
                    condition   : is_iaas !== undefined
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
            
        }
    }
}

function createbutton(button) {
    var class_span_button=(button.sprite ?'button-with-sprite':'button-without-sprite');
    return $('<span class="'+class_span_button+'"></span>').append(
               $('<span class="' +
                 (button.sprite ?
                     'kanopya-sprite kanopya-button-sprite ui-icon-' + button.sprite :
                     'ui-icon-' + button.icon) + '"></span>')
           ).append(
               $('<a>', { text : button.label })
           ).button().bind('click', function (e) {
        if (button.confirm && !confirm(button.confirm + ". Do you want to continue ?")) {
            return false;
        }
        if (typeof(button.action) === 'string') {
            $.ajax({
                url         : button.action,
                type        : 'POST',
                contentType : 'application/json',
                data        : JSON.stringify((button.data !== undefined) ? button.data : {})
            });
        } else {
            button.action(e);
        }
    });
}
