require('modalform.js');

function scomManagement(cid, eid) {
    
    // Warning dirty code here
    // TODO must be relative to a collector manager
    var scom_indicatorset_id = 5;

    var ServiceProviderList = new Array();
    $.ajax({
        url: '/api/serviceprovider',
        async: false,
        success: function(rows) {
            $(rows).each(function(row) {
                if ( rows[row].service_provider_id !== '1' ) {
                    ServiceProviderList.push(rows[row].service_provider_id);
                }
            });
        }
    });
    
    var indicators_grid_id = 'scom_indicators_list_' + eid;
    create_grid( {
        url                     : '/api/indicator?indicatorset_id=' + scom_indicatorset_id,
        content_container_id    : cid,
        grid_id                 : indicators_grid_id,
        grid_class              : 'scom_indicators_list',
        rowNum                  : 25,
        colNames                : [ 'id', 'name', 'oid', 'min', 'max', 'unit' ],
        colModel                : [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'indicator_name', index: 'indicator_name', width: 200,},
            { name: 'indicator_oid', index: 'indicator_oid', width: 200 },
            { name: 'indicator_min', index: 'indicator_min', width: 200 },
            { name: 'indicator_max', index: 'indicator_max', width: 200 },
            { name: 'indicator_unit', index: 'indicator_unit', width: 200 },
        ],
    } );

    function createIndicator(cid, eid) {
        var service_fields  = {
            indicator_name    : {
                label   : 'Name',
                type	: 'text',
            },
            indicator_oid	:{
                label	: 'OID',
                type	: 'text',
            },
            indicator_min    : {
                label	: 'Min',
                type	: 'text',
            },
            indicator_max	: {
                label	: 'Max',
                type	: 'text',
            },
            indicator_unit	:{
                label	: 'Unit',
                type	: 'text',
            },
        };
        var service_opts    = {
            title       : 'Create an indicator',
            name        : 'scomindicator',
            fields      : service_fields,
            beforeSubmit: function(Fdata, FjQuery, FAjaxOptions, FModalForm) {

                var beforeSubmitJSONData = {};
                $(Fdata).each( function() {
                   if (this.value) {
                       beforeSubmitJSONData[ this.name ] = this.value;
                   }
                } );

                ServiceProviderListSize = ServiceProviderList.length;
                for (var j=0; j < ServiceProviderListSize; j++) {
                        beforeSubmitJSONData.service_provider_id = ServiceProviderList[j];
                        $.ajax({
                            async: false,
                            url: '/api/scomindicator',
                            type: 'POST',
                            data: beforeSubmitJSONData,
                        });
                }

                // Insert the new indicator in 'indicator' table linked to scom_indicator_set :
                // WARNING : This is dutty fix for customer deadline compliance, SHOULD BE CHANGE BY REAL CODE :
                var indicatorFromScom = {};
                var indicator_min = beforeSubmitJSONData.indicator_min;
                var indicator_max = beforeSubmitJSONData.indicator_max;
                var indicator_name = beforeSubmitJSONData.indicator_name;
                var indicator_unit = beforeSubmitJSONData.indicator_unit;
                var indicator_oid = beforeSubmitJSONData.indicator_oid;
                indicatorFromScom = {"indicator_min": indicator_min, "indicator_name": indicator_name, "indicatorset_id": scom_indicatorset_id, "indicator_max": indicator_max, "indicator_unit": indicator_unit, "indicator_oid": indicator_oid };

                $.ajax({
                    async   : false,
                    url     : 'api/indicator',
                    type    : 'POST',
                    data    : indicatorFromScom,
                    success : function () {
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
        $('#' + cid).append(button);
    };

    createIndicator(cid, eid);

}