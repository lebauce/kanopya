require('common/grid.js');
require('common/service_common.js');
require('common/service_item_import.js');

var statistics_function_name = ['mean','variance','std','max','min','kurtosis','skewness','dataOut','sum'];

// return a map {indic_name => collector_indicator}
function getIndicators(sp_id) {
    // Retrieve all indicators associated to the collector manager of the service
    var indicators = {};
    $.ajax({
        // Get collector manager
        url     : '/api/serviceprovider/'+sp_id+'/service_provider_managers?expand=manager.collector_indicators.indicator&custom.category=CollectorManager',
        async   :false,
        success : function(service_provider) {
            if (service_provider.length > 0) {
                $(service_provider[0].manager.collector_indicators).each(function(i,collector_indic) {
                    var indicator = collector_indic.indicator;
                    indicators[indicator.indicator_label] = collector_indic;
                });
            }
        }
    });
    return indicators;
};

////////////////////////MONITORING MODALS//////////////////////////////////
function createServiceMetric(container_id, elem_id, ext, options) {
    function addServiceMetricDialog() {
        var indicators = getIndicators(elem_id);
        var indic_options = {};
        $.each(indicators, function (name, row) {
            indic_options[name] = row.collector_indicator_id;
        });

        var service_fields  = {
            clustermetric_label    : {
                label   : 'Name',
                type    : 'text'
            },
            clustermetric_statistics_function_name    : {
                label   : 'Statistic function name',
                type    : 'select',
                options   : statistics_function_name
            },
            clustermetric_indicator_id  :{
                label   : 'Indicator',
                type    : 'select',
                options : indic_options
            },
            clustermetric_window_time   :{
                type    : 'hidden',
                value   : '1200'
            },
            clustermetric_service_provider_id   :{
                type    : 'hidden',
                value   : elem_id
            },
            createcombination  :{
                label   : 'Create the associate combination',
                type    : 'checkbox',
                skip    : true
            }
        };
        var service_opts    = {
            title       : 'Create a Service Metric',
            name        : 'clustermetric',
            fields      : service_fields,
            error       : function(data) {
                $("div#waiting_default_insert").dialog("destroy");
            },
            callback    : function(elem, form) {
                    $("#service_resources_clustermetrics_"  + elem_id).trigger('reloadGrid');
                    if ($(form).find('#input_createcombination').attr('checked')) {
                        $.ajax({
                            url     : '/api/aggregatecombination',
                            type    : 'POST',
                            data    : {
                                aggregate_combination_label     : elem.clustermetric_label,
                                service_provider_id             : elem_id,
                                aggregate_combination_formula   : 'id' + elem.pk
                            },
                            success : function() {
                                $("#service_resources_aggregate_combinations_" + elem_id).trigger('reloadGrid');
                            }
                        });
                    }
            },
            beforeSubmit: (options && options.beforeSubmit) || $.noop
        };

        mod = new ModalForm(service_opts);
        mod.start();
    }
    var button = $("<button>", {html : 'Add a service metric'});
    button.bind(
            'click',
            addServiceMetricDialog
    ).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function createServiceCombination(container_id, elem_id, options) {
    var service_fields  = {
        aggregate_combination_label     : {
            label   : 'Name',
            type    : 'text'
        },
        aggregate_combination_formula   : {
            label   : 'Formula',
            type    : 'text'
        },
        service_provider_id             : {
            type    : 'hidden',
            value   : elem_id
        }
    };
    var service_opts    = {
        title       : 'Create a Combination',
        name        : 'aggregatecombination',
        fields      : service_fields,
        callback    : function() {
            $('#service_resources_aggregate_combinations_' + elem_id).trigger('reloadGrid');
        },
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        beforeSubmit: (options && options.beforeSubmit) || $.noop
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

            makeAutocompleteAndTranslate( $( "#input_aggregate_combination_formula" ), availableTags );

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
            type    : 'text'
        },
        nodemetric_combination_formula  : {
            label   : 'Indicators Formula',
            type    : 'text'
        },
        service_provider_id             : {
            type    : 'hidden',
            value   : elem_id
        }
    };
    var service_opts    = {
        title       : 'Create a Combination',
        name        : 'nodemetriccombination',
        fields      : service_fields,
        error       : function(data) {
            $("div#waiting_default_insert").dialog("destroy");
        },
        callback    : function() {
            $('#service_resources_nodemetric_combination_' + elem_id).trigger('reloadGrid');
        },
        beforeSubmit: (options && options.beforeSubmit) || $.noop
    };

    var button = $("<button>", {html : 'Add a combination'});
    button.bind('click', function() {
        mod = new ModalForm(service_opts);
        mod.start();
        ////////////////////////////////////// Node Combination Forumla Construction ///////////////////////////////////////////

        var availableTags = new Array();
        var indicators = getIndicators(elem_id, ext);
        for (var indic in indicators) {
            availableTags.push({label : indic, value : indicators[indic].collector_indicator_id});
            //availableTags.push({indicators});
        }

        makeAutocompleteAndTranslate( $( "#input_nodemetric_combination_formula" ), availableTags );

        ////////////////////////////////////// END OF : Node Combination Forumla Construciton ///////////////////////////////////////////

    }).button({ icons : { primary : 'ui-icon-plusthick' } });
    $('#' + container_id).append(button);
};

function loadServicesMonitoring(container_id, elem_id, ext, mode_policy) {

    var container   = $("#" + container_id);

    var external        = ext || '';

    // Nodemetric bargraph details handler
    function nodeMetricDetailsBargraph(cid, nodeMetric_id) {
      integrateWidget(cid, 'widget_nodes_bargraph', function(widget_div) {
          widget_div.find('.indicator_dropdown').remove();
          widget_div.find('.nodes_order_selection').hide();
          showNodemetricCombinationBarGraph(widget_div, nodeMetric_id, '', elem_id);
      });
    }

    // Nodemetric histogram details handler
    function nodeMetricDetailsHistogram(cid, nodeMetric_id) {
      integrateWidget(cid, 'widget_nodes_histogram', function(widget_div) {
          widget_div.find('.indicator_dropdown').remove();
          widget_div.find('.part_number_input').remove();
          showNodemetricCombinationHistogram(widget_div, nodeMetric_id, '', 10, elem_id);
      });
    }

    // Nodemetric historical details handler
    function nodeMetricDetailsHistorical(cid, nodeMetric_id) {
        integrateWidget(cid, 'widget_historical_view', function(widget_div) {
          customInitHistoricalWidget(
              widget_div,
              elem_id,
              {
                  clustermetric_combinations : null,
                  nodemetric_combinations    : [{id:nodeMetric_id, name:'', unit:''}],
                  nodes                      : 'from_ajax'
              },
              {open_config_part : true}
          );
      });
    }

    // Clustermetric historical graph details handler
    function clusterMetricCombinationDetailsHistorical(cid, clusterMetric_id, row_data) {
        integrateWidget(cid, 'widget_historical_view', function(widget_div) {
            customInitHistoricalWidget(
                widget_div,
                elem_id,
                {
                    clustermetric_combinations : [{id:clusterMetric_id, name:row_data.aggregate_combination_label, unit:row_data.combination_unit}],
                    nodemetric_combinations    : 'from_ajax',
                    nodes                      : 'from_ajax'
                },
                {allow_forecast : true}
            );
      });
    }

    ////////////////////////MONITORING ACCORDION//////////////////////////////////

    var divacc = $('<div id="accordion_monitoring_rule">').appendTo(container);
    $('<h3><a href="#">Node</a></h3>').appendTo(divacc);

    var node_monitoring_accordion_container = $('<div>', {id : 'node_monitoring_accordion_container'});
    divacc.append(
        node_monitoring_accordion_container.append(
            $('<div>')
                .append( $('<div>', {id : 'node_metrics_action_buttons', class : 'action_buttons'}) )
                .append( $('<div>', {id : 'node_metrics_container'}) )
        )
    );

    var nodemetriccombi_grid_id = 'service_resources_nodemetric_combination_' + elem_id;
    createNodemetricCombination('node_metrics_action_buttons', elem_id, (external !== '') ? true : false);
    if (!mode_policy) {
        importItemButton(
                node_monitoring_accordion_container.find('#node_metrics_action_buttons'),
                elem_id,
                {
                    name        : 'combination',
                    label_attr  : 'nodemetric_combination_label',
                    desc_attr   : 'formula_label',
                    type        : 'nodemetric_combination'
                },
                [nodemetriccombi_grid_id]
        );
    }
    create_grid( {
        caption : 'Nodemetric Combinations',
        url: '/api/nodemetriccombination?service_provider_id=' + elem_id,
        content_container_id: 'node_metrics_container',
        grid_id: nodemetriccombi_grid_id,
        colNames: [ 'id', 'Name', 'Indicators formula', 'Indicators formula brut' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 90, sorttype: 'int', hidden: true, key: true },
            { name: 'nodemetric_combination_label', index: 'nodemetric_combination_label', width: 120 },
            { name: 'formula_label', index: 'formula_label', width: 170 },
            { name: 'nodemetric_combination_formula', index: 'nodemetric_combination_formula', hidden: true }
        ],
        details: {
            tabs : [
                    { label : 'Nodes graph', id : 'nodesgraph', onLoad : nodeMetricDetailsBargraph },
                    { label : 'Histogram'  , id : 'histogram' , onLoad : nodeMetricDetailsHistogram },
                    { label : 'Historical' , id : 'historical', onLoad : nodeMetricDetailsHistorical }
                ],
            title   : { from_column : 'nodemetric_combination_label' },
            height  : 600,
            buttons : ['button-ok']
        },
        deactivate_details  : mode_policy,
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/nodemetriccombination/', id, [nodemetriccombi_grid_id]);
            }
        },
        multiselect : !mode_policy,
        multiactions : {
            multiDelete : {
                label       : 'Delete node combination(s)',
                action      : removeGridEntry,
                url         : '/api/nodemetriccombination',
                icon        : 'ui-icon-trash',
                extraParams : {multiselect : true}
            }
        }
    } );

    $('<h3><a href="#">Service</a></h3>').appendTo(divacc);

    var clustermetric_grid_id = 'service_resources_clustermetrics_' + elem_id;
    var aggregatecombi_grid_id = 'service_resources_aggregate_combinations_' + elem_id;
    var service_monitoring_accordion_container = $('<div>', {id : 'service_monitoring_accordion_container'});
    divacc.append(
        service_monitoring_accordion_container.append(
            $('<div>')
                .append( $('<div>', {id : 'service_metrics_action_buttons', class : 'action_buttons'}) )
                .append( $('<div>', {id : 'service_metrics_container'}) )
        )
    );

    createServiceMetric('service_metrics_action_buttons', elem_id, (external !== '') ? true : false);
    create_grid( {
        caption : 'Metrics',
        url: '/api/serviceprovider/' + elem_id + '/clustermetrics',
        content_container_id: 'service_metrics_container',
        grid_id: clustermetric_grid_id,
        colNames: [ 'id', 'Name', 'Function', 'Indicator' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
            { name: 'clustermetric_label', index: 'clustermetric_label', width: 90 },
            { name: 'clustermetric_statistics_function_name', index: 'clustermetric_statistics_function_name', width: 90 },
            { name: 'indicator_label', index: 'indicator_label', width: 200 }
        ],
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/clustermetric/', id, [clustermetric_grid_id, aggregatecombi_grid_id]);
            }
        },
        deactivate_details  : mode_policy,
        multiselect : !mode_policy,
        multiactions : {
            multiDelete : {
                label       : 'Delete service metric(s)',
                action      : removeGridEntry,
                url         : '/api/clustermetric',
                icon        : 'ui-icon-trash',
                extraParams : {multiselect : true}
            }
        }
    } );

    $("<p>").appendTo('#service_monitoring_accordion_container');

    service_monitoring_accordion_container.append(
        $('<div>')
            .append( $('<div>', {id : 'service_metric_comb_action_buttons', class : 'action_buttons'}) )
            .append( $('<div>', {id : 'service_metric_comb_container'}) )
    );

    createServiceCombination('service_metric_comb_action_buttons', elem_id);
    if (!mode_policy) {
        importItemButton(
                service_monitoring_accordion_container.find('#service_metric_comb_action_buttons'),
                elem_id,
                {
                    name        : 'combination',
                    label_attr  : 'aggregate_combination_label',
                    desc_attr   : 'formula_label',
                    type        : 'aggregate_combination'
                },
                [clustermetric_grid_id, aggregatecombi_grid_id]
        );
    }
    create_grid( {
        caption: 'Metric combinations',
        url: '/api/aggregatecombination?service_provider_id=' + elem_id,
        content_container_id: 'service_metric_comb_container',
        grid_id: aggregatecombi_grid_id,
        colNames: [ 'id', 'Name', 'Formula', 'Unit' ],
        colModel: [
            { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
            { name: 'aggregate_combination_label', index: 'aggregate_combination_label', width: 90 },
            { name: 'formula_label', index: 'formula_label', width: 200 },
            { name: 'combination_unit', index: 'combination_unit',  hidden: true }
        ],
        details: {
            tabs : [
                    { label : 'Historical graph', id : 'servicehistoricalgraph', onLoad : clusterMetricCombinationDetailsHistorical }
                ],
            title       : { from_column : 'aggregate_combination_label' },
            height      : 600,
            buttons     : ['button-ok']
        },
        deactivate_details  : mode_policy,
        action_delete: {
            callback : function (id) {
                confirmDeleteWithDependencies('/api/aggregatecombination/', id, [aggregatecombi_grid_id]);
            }
        },
        multiselect : !mode_policy,
        multiactions : {
            multiDelete : {
                label       : 'Delete service combination(s)',
                action      : removeGridEntry,
                url         : '/api/aggregatecombination',
                icon        : 'ui-icon-trash',
                extraParams : {multiselect : true}
            }
        }
    } );

    $('#accordion_monitoring_rule').accordion({
        autoHeight  : false,
        active      : false,
        change      : function (event, ui) {
            // Set all grids size to fit accordion content
            ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
        }
    });
};
