require('modalform.js');

function scomManagement(cid, eid) {
    
    // Get service providers list :
    var serviceProvider;
    $.ajax({
        url: '/api/serviceprovider',
        async: false,
        success: function(rows) {
            $(rows).each(function(row) {
                serviceProvider = rows[1].externalcluster_id;
            });
        }
    });
    
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
    
    var loadServicesRessourcesGridId = 'scom_indicators_list_' + eid;
    create_grid( {
        url: '/api/scomindicator?service_provider_id=' + serviceProvider,
        content_container_id: cid,
        grid_id: loadServicesRessourcesGridId,
        grid_class: 'scom_indicators_list',
        colNames: [ 'id', 'name', 'oid', 'min', 'max', 'unit' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'scom_indicator_name', index: 'scom_indicator_name', width: 200,},
            { name: 'scom_indicator_oid', index: 'scom_indicator_oid', width: 200 },
            { name: 'scom_indicator_min', index: 'scom_indicator_min', width: 200 },
            { name: 'scom_indicator_max', index: 'scom_indicator_max', width: 200 },
            { name: 'scom_indicator_unit', index: 'scom_indicator_unit', width: 200 },
        ],
    } );
    $('scom_indicators_list').jqGrid('setGridWidth', $(cid).parent().width()-20);
    
    function createIndicator(cid, eid) {
    var service_fields  = {
        scom_indicator_name    : {
            label   : 'Name',
            type	: 'text',
        },
        scom_indicator_oid	:{
        	label	: 'OID',
        	type	: 'text',
        },
        scom_indicator_min    : {
            label	: 'Min',
        	type	: 'text',
        },
        scom_indicator_max	: {
        	label	: 'Max',
        	type	: 'text',	
        },
        scom_indicator_unit	:{
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
               beforeSubmitJSONData[ this.name ] = this.value;
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
            
            // Insert the new indicator in 'indicator' table :
            // WARNING : This is dutty fix for customer deadline compliance, SHOULD BE CHANGE BY REAL CODE :
            var scom_indicatorset_id = 5;
            var indicator_min = Fdata.scom_indicator_min;
            var indicator_max = Fdata.scom_indicator_max;
            var indicator_name = Fdata.scom_indicator_name;
            var indicator_unit = Fdata.scom_indicator_unit;
            var indicator_oid = Fdata.scom_indicator_oid;
            var indicatorFromScom = { "indicator_min" : indicator_min, "indicator_name" : indicator_name, "indicatorset_id" : scom_indicatorset_id, "indicator_max" : indicator_max, "indicator_unit" : indicator_unit, "indicator_oid" : indicator_oid };
            
            console.log(indicatorFromScom);
            
            $.ajax({
                async: false,
                url: 'api/indicator',
                type: 'POST',
                data: indicatorFromScom,
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