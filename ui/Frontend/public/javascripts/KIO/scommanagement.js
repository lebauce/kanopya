require('modalform.js');

/*
 * TEMPORARY BAD indicator management
 * list indicator from scom indicator set
 * allow user to add a scom indicator
 * the new indicator will be added to indicators of set scom and linked to all existing connector of category collectorManager (via collector_indicator)
 * THIS IS BAD
 * TODO : indicator list and add per collector manager
 */

function scomManagement(cid, eid) {
    
    // Warning dirty code here
    // TODO must be relative to a collector manager
    var scom_indicatorset_id = 5;


    var indicators_grid_id = 'scom_indicators_list_' + eid;
    var action_buttons_container = $('#' + cid).prevAll('.action_buttons');

    createIndicator(action_buttons_container, eid);
    create_grid( {
        url                     : '/api/indicator?indicatorset_id=' + scom_indicatorset_id,
        content_container_id    : cid,
        grid_id                 : indicators_grid_id,
        grid_class              : 'scom_indicators_list',
        rowNum                  : 25,
        colNames                : [ 'Id', 'Label', 'OID', 'Min', 'Max', 'Unit' ],
        colModel                : [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'indicator_label', index: 'indicator_label', width: 200 },
            { name: 'indicator_oid', index: 'indicator_oid', width: 200 },
            { name: 'indicator_min', index: 'indicator_min', width: 200 },
            { name: 'indicator_max', index: 'indicator_max', width: 200 },
            { name: 'indicator_unit', index: 'indicator_unit', width: 200 }
        ],
        action_delete           : {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/indicator/', id, [indicators_grid_id]);
            }
        },
        multiselect             : true,
        multiactions : {
            multiDelete : {
                label       : 'Delete indicator(s)',
                action      : removeGridEntry,
                url         : '/api/indicator',
                extraParams : {multiselect : true},
                icon        : 'ui-icon-trash'
            }
        }
    } );

    function createIndicator(container, eid) {
        var service_fields  = {
            indicator_label : {
                label   : 'Label',
                type	: 'text'
            },
            indicator_oid	: {
                label	: 'OID',
                type	: 'text'
            },
            indicator_min    : {
                label	: 'Min',
                type	: 'text'
            },
            indicator_max	: {
                label	: 'Max',
                type	: 'text'
            },
            indicator_unit	: {
                label	: 'Unit',
                type	: 'text'
            },
        };
        var service_opts    = {
            title       : 'Create an indicator',
            name        : 'indicator',
            fields      : service_fields,
            beforeSubmit: function(Fdata, FjQuery, FAjaxOptions, FModalForm) {

                var beforeSubmitJSONData = {};
                $(Fdata).each( function() {
                   if (this.value) {
                       beforeSubmitJSONData[ this.name ] = this.value;
                   }
                } );

                // Insert the new indicator in 'indicator' table linked to scom_indicator_set :
                // WARNING : This is dutty fix for customer deadline compliance, SHOULD BE CHANGE BY REAL CODE :
                var indicatorFromScom = {
                        "indicatorset_id"   : scom_indicatorset_id,
                        "indicator_label"   : beforeSubmitJSONData.indicator_label,
                        "indicator_name"    : beforeSubmitJSONData.indicator_label,
                        "indicator_min"     : beforeSubmitJSONData.indicator_min,
                        "indicator_max"     : beforeSubmitJSONData.indicator_max,
                        "indicator_unit"    : beforeSubmitJSONData.indicator_unit,
                        "indicator_oid"     : beforeSubmitJSONData.indicator_oid };

                $.ajax({
                    async   : false,
                    url     : 'api/indicator',
                    type    : 'POST',
                    data    : indicatorFromScom,
                    success : function (new_indic) {
                        // Link the new connector to all collector_manager (BAD)
                        $.ajax({
                            url: '/api/component?component_type.component_type_categories.component_category.category_name=CollectorManager',
                            success: function(collector_manager_connectors) {
                                $(collector_manager_connectors).each(function(i,connector) {
                                    $.ajax({
                                      url: '/api/collectorindicator',
                                      type: 'POST',
                                      data: {
                                          indicator_id          : new_indic.pk,
                                          collector_manager_id  : connector.pk
                                      }
                                  });
                                });
                            }
                        });

                        $('#' + indicators_grid_id).trigger('reloadGrid');
                    }
                });

                FModalForm.closeDialog();
                return false;
            },
        };

        var button = $("<button>", {html : 'Add indicator'});
        button.bind('click', function() {
            mod = new ModalForm(service_opts);
            mod.start();
        }).button({ icons : { primary : 'ui-icon-plusthick' } });
        container.append(button);
    };
}