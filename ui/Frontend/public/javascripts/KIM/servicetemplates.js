require('common/notification_subscription.js');

function load_service_template_content (container_id) {
    function createAddServiceTemplateButton(cid, grid) {
        var button = $("<button>", { html : 'Add a service'} ).button({
            icons   : { primary : 'ui-icon-plusthick' }
        });

        button.bind('click', function() {
            // Use the kanopyaformwizard for policies
            (new KanopyaFormWizard({
                title         : 'Add a service',
                type          : 'servicetemplate',
                reloadable    : true,
                displayed     : [ 'service_name', 'service_desc' ],
                attrsCallback : function (resource, data) {
                    var attributes = ajax('POST', '/api/' + resource + '/getServiceTemplateDef', data);

                    // Set the value if defined (at reload)
                    $.each([ 'service_name', 'service_desc' ], function (index, attr) {
                        if (data[attr] !== undefined) {
                            attributes.attributes[attr].value = data[attr];
                        }
                    });
                    return attributes;
                },
                callback : function () { grid.trigger("reloadGrid"); }
            })).start();
        });
        $('#' + cid).append(button);
    };

    var container = $('#' + container_id);
    var grid = create_grid( {
        url: '/api/servicetemplate',
        content_container_id: container_id,
        grid_id: 'service_template_list',
        colNames: [ 'ID', 'Name', 'Description', '' ],
        colModel: [ { name: 'service_template_id', index:'service_template_id', width:60, sorttype:"int", hidden:true, key:true},
                    { name: 'service_name', index: 'service_name', width:300 },
                    { name: 'service_desc', index: 'service_desc', width:500 },
                    { name: 'subscribe', index : 'subscribe', width : 40, align : 'center', nodetails : true }],
        afterInsertRow: function(grid, rowid, rowdata, rowelem) {
            var cell            = $(grid).find('tr#' + rowid).find('td[aria-describedby="service_template_list_subscribe"]');
            var subscribeButton = $('<div>').button({ text : false, icons : { primary : 'ui-icon-mail-closed' } }).appendTo(cell);
            $(subscribeButton).attr('style', 'margin-top:5px;');
            $(subscribeButton).click(function() {
                var details = {
                    tabs : [
                        { label : 'Notification subscriptions', id : 'subscription', onLoad : function(cid, eid) { loadSubscriptionModal(cid, eid, 'AddCluster'); } }
                    ],
                    title : 'Notification subscriptions'
                };
                show_detail('entity_subscription_list', 'entity_subscription_list', rowelem.pk, rowdata, details);
            });
        }
    } );

    createAddServiceTemplateButton(container_id, grid);
}

function load_service_template_details (elem_id, row_data, grid_id) {
    // Use the kanopyaformwizard for policies
    (new KanopyaFormWizard({
        title     : 'Edit service template: ' + row_data.service_name,
        id        : elem_id,
        type      : 'servicetemplate',
        displayed : [ 'service_name', 'service_desc', 'hosting_policy_id', 'storage_policy_id', 'network_policy_id',
                      'scalability_policy_id', 'system_policy_id', 'billing_policy_id', 'orchestration_policy_id' ],
        callback : function () { $('#' + grid_id).trigger("reloadGrid"); }
    })).start();
}
