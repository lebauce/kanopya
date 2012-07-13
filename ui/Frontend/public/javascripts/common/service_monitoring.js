require('common/grid.js');

var statistics_function_name = ['mean','variance','std','max','min','kurtosis','skewness','dataOut','sum'];

// return a map {indic_name => indic_id}
function getIndicators(sp_id, ext) {
    // We are not supposed to directly access indicatorset and indicator
    // TODO use associated CollectorManager to retrieve indicators info (one request)
    //      or indicators toString() (one request/indicator)
    var indicatorsets = {};
    $.ajax({
        async   : false,
        url: '/api/indicatorset',
        success: function(rows) {
            $(rows).each(function(row) {
                indicatorsets[rows[row].indicatorset_id] = rows[row];
            });
        }
    });

    var indicators = {};
    $.ajax({
        async   : false,
        url: (ext) ? '/api/scomindicator?service_provider_id=' + sp_id : '/api/indicator',
        success: function(rows) {
            $(rows).each(function(row) {
                if (ext) {
                    indicators[rows[row].scom_indicator_name]   = rows[row].scom_indicator_id;
                } else {
                    var indicatorset_name = indicatorsets[rows[row].indicatorset_id].indicatorset_name;
                    var indic_fullname =  indicatorset_name + '/' + rows[row].indicator_name;
                    indicators[indic_fullname] = rows[row];

                    // THis version use indicator toString but is slow (and indicators name are quoted)
//                    $.ajax({
//                        async       : false,
//                        type        : 'POST',
//                        data        : JSON.stringify({}),
//                        contentType : 'application/json',
//                        url         : '/api/indicator/' + rows[row].indicator_id + '/toString',
//                        complete    : function(jqXHR, status) {
//                            if (status === 'success') {
//                                indicators[jqXHR.responseText] = rows[row].indicator_id;
//                            }
//                        }
//                    });

                }
            });
        }
    });

    return indicators;
};

////////////////////////MONITORING MODALS//////////////////////////////////
function createServiceMetric(container_id, elem_id, ext, options) {

    ext = ext || false;
    
    var indicators = getIndicators(elem_id, ext);
    var indic_options = {};
    $.each(indicators, function (name, row) {
        indic_options[name] = row.indicator_id;
    });

    var service_fields  = {
        clustermetric_label    : {
            label   : 'Name',
            type    : 'text',
        },
        clustermetric_statistics_function_name    : {
            label   : 'Statistic function name',
            type    : 'select',
            options   : statistics_function_name,
        },
        clustermetric_indicator_id  :{
            label   : 'Indicator',
            type    : 'select',
            options : indic_options,
        },
        clustermetric_window_time   :{
            type    : 'hidden',
            value   : '1200',
        },
        clustermetric_service_provider_id   :{
            type    : 'hidden',
            value   : elem_id,  
        },
        createcombination  :{
            label   : 'Create the associate combination',
            type    : 'checkbox',
            skip    : true,
        },
    };
    var service_opts    = {
        title       : 'Create a Service Metric',
        name        : 'clustermetric',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function(elem, form) {
                $("#service_ressources_clustermetrics_"  + elem_id).trigger('reloadGrid');
                if ($(form).find('#input_createcombination').attr('checked')) {
                    $.ajax({
                        url     : '/api/aggregatecombination',
                        type    : 'POST',
                        data    : {
                            aggregate_combination_label               : elem.clustermetric_label,
                            aggregate_combination_service_provider_id : elem_id,
                            aggregate_combination_formula             : 'id' + elem.pk,
                        },
                        success : function() {
                            $("#service_ressources_aggregate_combinations_" + elem_id).trigger('reloadGrid');
                        }
                    });
                }
        },
        beforeSubmit: (options && options.beforeSubmit) || $.noop,
    };

    var button = $("<button>", {html : 'Add a service metric'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceConbination(container_id, elem_id, options) {
    var service_fields  = {
        aggregate_combination_label    : {
            label   : 'Name',
            type    : 'text',
        },
        aggregate_combination_formula    : {
            label   : 'Formula',
            type    : 'text',
        },
        aggregate_combination_service_provider_id   :{
            type    : 'hidden',
            value   : elem_id,  
        },
    };
    var service_opts    = {
        title       : 'Create a Combination',
        name        : 'aggregatecombination',
        fields      : service_fields,
        callback    : function() {
            $('#service_ressources_aggregate_combinations_' + elem_id).trigger('reloadGrid');
        },
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        beforeSubmit: (options && options.beforeSubmit) || $.noop,
    };

    var button = $("<button>", {html : 'Add a combination'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
                    ////////////////////////////////////// Service Combination Forumla Construction ///////////////////////////////////////////
        
        $(function() {
    var availableTags = new Array();
    $.ajax({
        url: '/api/clustermetric?clustermetric_service_provider_id=' + elem_id + '&dataType=jqGrid',
        async   : false,
        success: function(answer) {
                    $(answer.rows).each(function(row) {
                    var pk = answer.rows[row].pk;
                    availableTags.push({label : answer.rows[row].clustermetric_label, value : answer.rows[row].clustermetric_id});

                });
            }
    });

    function split( val ) {
            return val.split( / \s*/ );
        }
        function extractLast( term ) {
            return split( term ).pop();
        }

        $( "#input_aggregate_combination_formula" )
            // don't navigate away from the field on tab when selecting an item
            .bind( "keydown", function( event ) {
                if ( event.keyCode === $.ui.keyCode.TAB &&
                        $( this ).data( "autocomplete" ).menu.active ) {
                    event.preventDefault();
                }
            })
            .autocomplete({
                minLength: 0,
                source: function( request, response ) {
                    // delegate back to autocomplete, but extract the last term
                    response( $.ui.autocomplete.filter(
                        availableTags, extractLast( request.term ) ) );
                },
                focus: function() {
                    // prevent value inserted on focus
                    return false;
                },
                select: function( event, ui ) {
                    var terms = split( this.value );
                    // remove the current input
                    terms.pop();
                    // add the selected item
                    terms.push( "id" + ui.item.value );
                    // add placeholder to get the comma-and-space at the end
                    //terms.push( "" );
                    this.value = terms;
                    this.value = terms.join(" ");
                    return false;
                }
            });
    });
    ////////////////////////////////////// END OF : Service Combination Forumla Construction ///////////////////////////////////////////

    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createNodemetricCombination(container_id, elem_id, ext, options) {
    ext     = ext || false;
    var service_fields  = {
        nodemetric_combination_label    : {
            label   : 'Name',
            type    : 'text',
        },
        nodemetric_combination_formula    : {
            label   : 'Indicators Formula',
            type    : 'text',
        },
        nodemetric_combination_service_provider_id  :{
            type    : 'hidden',
            value   : elem_id,
        },
    };
    var service_opts    = {
        title       : 'Create a Combination',
        name        : 'nodemetriccombination',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            $('#service_ressources_nodemetric_combination_' + elem_id).trigger('reloadGrid');
        },
        beforeSubmit: (options && options.beforeSubmit) || $.noop,
    };

    var button = $("<button>", {html : 'Add a combination'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
            ////////////////////////////////////// Node Combination Forumla Construction ///////////////////////////////////////////
            
//        var component_id;
//        var indicators;
//        $.ajax({
//            async : false,
//            type : 'POST',
//            url:'/api/serviceprovider/' + elem_id + '/getManager',
//            data : {
//                manager_type : 'collector_manager'
//            },
//            success : function(row) {
//                component_id = row.component_id;
//            }
//        });
//
//        $.ajax({
//            async : false,
//            type : 'POST',
//            url:'/api/component/' + component_id + '/getIndicators',
//            data : {},
//            success : function(row) {
//                indicators = row;
//                console.log(indicators);
//            }
//        });

        var availableTags = new Array();
        var indicators = getIndicators(elem_id, ext);
        for (var indic in indicators) {
            availableTags.push({label : indic, value : indicators[indic].indicator_id});
            //availableTags.push({indicators});
        }

        function split( val ) {
            return val.split( / \s*/ );
        }
        function extractLast( term ) {
            return split( term ).pop();
        }

        $( "#input_nodemetric_combination_formula" )
            // don't navigate away from the field on tab when selecting an item
            .bind( "keydown", function( event ) {
                if ( event.keyCode === $.ui.keyCode.TAB &&
                        $( this ).data( "autocomplete" ).menu.active ) {
                    event.preventDefault();
                }
            })
            .autocomplete({
                minLength: 0,
                source: function( request, response ) {
                    // delegate back to autocomplete, but extract the last term
                    response( $.ui.autocomplete.filter(
                        availableTags, extractLast( request.term ) ) );
                },
                focus: function() {
                    // prevent value inserted on focus
                    return false;
                },
                select: function( event, ui ) {
                    var terms = split( this.value );
                    // remove the current input
                    terms.pop();
                    // add the selected item
                    terms.push( "id" + ui.item.value );
                    // add placeholder to get the comma-and-space at the end
                    //terms.push( "" );
                    this.value = terms;
                    this.value = terms.join(" ");
                    return false;
                }
            });

    ////////////////////////////////////// END OF : Node Combination Forumla Construciton ///////////////////////////////////////////

    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function loadServicesMonitoring(container_id, elem_id, ext, mode_policy) {

    var container   = $("#" + container_id);

    var external    = ext || '';

    // Nodemetric bargraph details handler
    function nodeMetricDetailsBargraph(cid, nodeMetric_id) {
      // Use dashboard widget outside of the dashboard
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_nodes_bargraph.html', function() {
          $('.indicator_dropdown').remove();
          showNodemetricCombinationBarGraph(graph_div, nodeMetric_id, '', elem_id);
      });
    }

    // Nodemetric histogram details handler
    function nodeMetricDetailsHistogram(cid, nodeMetric_id) {
      // Use dashboard widget outside of the dashboard
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_nodes_histogram.html', function() {
          $('.indicator_dropdown').remove();
          $('.part_number_input').remove();
          showNodemetricCombinationHistogram(graph_div, nodeMetric_id, '', 10, elem_id);
      });
    }

    // Clustermetric historical graph details handler
    function clusterMetricDetailsHistorical(cid, clusterMetric_id) {
      // Use dashboard widget outside of the dashboard
      var cont = $('#' + cid);
      var graph_div = $('<div>', { 'class' : 'widgetcontent' });
      cont.addClass('widget');
      cont.append(graph_div);
      graph_div.load('/widgets/widget_historical_service_metric.html', function() {
          $('.dropdown_container').remove();
          setdatePicker(graph_div);
          setRefreshButton(graph_div, clusterMetric_id, '', elem_id);
          showCombinationGraph(graph_div, clusterMetric_id, '', '', '', elem_id);
      });
    }

    ////////////////////////MONITORING ACCORDION//////////////////////////////////

    var divacc = $('<div id="accordion_monitoring_rule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);
    $('<div id="node_monitoring_accordion_container">').appendTo(divacc);
    var container = $("#" + container_id);
    
    $("<p>", { html : "Nodemetric Combinations  : " }).appendTo('#service_monitoring_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_nodemetric_combination_' + elem_id;
    create_grid( {
        url: '/api/serviceprovider/' + elem_id + '/nodemetric_combinations',
        content_container_id: 'node_monitoring_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/nodemetriccombination/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'nodemetric_combination_formula_tostring');
        },
        colNames: [ 'id', 'name', 'indicators formula', 'indicators formula brut' ],
        colModel: [ 
            { name: 'pk', index: 'pk', width: 90, sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_combination_label', index: 'nodemetric_combination_label', width: 120 },
            { name: 'nodemetric_combination_formula_tostring', index: 'nodemetric_combination_formula_tostring', width: 170 },
            { name: 'nodemetric_combination_formula', index: 'nodemetric_combination_formula', hidden: true },
        ],
        details: {
            tabs : [
                    { label : 'Nodes graph', id : 'nodesgraph', onLoad : nodeMetricDetailsBargraph },
                    { label : 'Histogram', id : 'histogram', onLoad : nodeMetricDetailsHistogram },
                ],
            title : { from_column : 'nodemetric_combination_label' }
        },
        deactivate_details  : mode_policy,
        action_delete: {
            url : '/api/nodemetriccombination',
        }
    } );
    createNodemetricCombination('node_monitoring_accordion_container', elem_id, (external !== '') ? true : false);


    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);
    $('<div id="service_monitoring_accordion_container">').appendTo(divacc);
   
    var loadServicesMonitoringGridId = 'service_ressources_clustermetrics_' + elem_id;
    create_grid( {
        caption : 'Metrics',
        url: '/api/serviceprovider/' + elem_id + '/clustermetrics',
        content_container_id: 'service_monitoring_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'clustermetric_indicator_id');
            var url = '/api/indicator/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'clustermetric_indicator_id');
            
        },
        colNames: [ 'id', 'name', 'function', 'indicator' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
            { name: 'clustermetric_label', index: 'clustermetric_label', width: 90 },
            { name: 'clustermetric_statistics_function_name', index: 'clustermetric_statistics_function_name', width: 90 },
            { name: 'clustermetric_indicator_id', index: 'clustermetric_indicator_id', width: 200 },
        ],
        action_delete: {
            url : '/api/clustermetric',
        },
        deactivate_details  : mode_policy,
    } );
    createServiceMetric('service_monitoring_accordion_container', elem_id, (external !== '') ? true : false);
    
    $("<p>").appendTo('#service_monitoring_accordion_container');
    var loadServicesMonitoringGridId = 'service_ressources_aggregate_combinations_' + elem_id;
    create_grid( {
        caption: 'Metric combinations',
        url: '/api/serviceprovider/' + elem_id + '/aggregate_combinations',
        content_container_id: 'service_monitoring_accordion_container',
        grid_id: loadServicesMonitoringGridId,
        afterInsertRow: function(grid, rowid) {
            var id  = $(grid).getCell(rowid, 'pk');
            var url = '/api/aggregatecombination/' + id + '/toString';
            setCellWithCallMethod(url, grid, rowid, 'aggregate_combination_formula');
        },
        colNames: [ 'id', 'name', 'formula' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'aggregate_combination_label', index: 'aggregate_combination_label', width: 90 },
            { name: 'aggregate_combination_formula', index: 'aggregate_combination_formula', width: 200 },
        ],
        details: {
            tabs : [
                    { label : 'Historical graph', id : 'servicehistoricalgraph', onLoad : clusterMetricDetailsHistorical },
                ],
            title : { from_column : 'aggregate_combination_label' }
        },
        deactivate_details  : mode_policy,
        action_delete: {
            url : '/api/aggregatecombination',
        },
    } );
    createServiceConbination('service_monitoring_accordion_container', elem_id);
    
    $('#accordion_monitoring_rule').accordion({
        autoHeight  : false,
        active      : false,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    });
};
