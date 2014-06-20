require('common/grid.js');
require('common/service_common.js');
require('common/service_item_import.js');

var statistics_function_name = ['mean','variance','std','max','min','kurtosis','skewness','dataOut','sum'];

// return a map {indic_name => collector_indicator}
function getIndicators(sp_id) {
    // Retrieve all indicators associated to the collector manager of the service-
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

function openCreateDialog() {

    var dialogContainerId = 'metric-editor';
    var metricCategoryData, metricData;

    function loadMetricCategoryData() {
        $.getJSON("ajax/metric-category.json", function(data) {
            metricCategoryData = data;
            loadMetricData();
        });
    }

    function loadMetricData() {
        $.getJSON("ajax/metric.json", function(data) {
            metricData = data;
            renderDialogTemplate();
        });
    }

    function renderDialogTemplate() {
        var templateFile = '/templates/metric-editor.tmpl.html';
        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('body').append(template(metricCategoryData));
            blocklyHandler.init(metricCategoryData, metricData);
            openDialog();
        });
    }

    function openDialog() {
        $('#' + dialogContainerId).dialog({
            resizable: true,
            modal: true,
            dialogClass: "no-close",
            width: 800,
            height: 600,
            buttons : [
                {
                    id: 'but-cancel',
                    text: 'Cancel',
                    click: function() {
                        closeDialog(this);
                    }
                },
                {
                    id: 'but-create',
                    text: 'Create',
                    click: function() {
                        if (createMetric()) {
                            closeDialog(this);
                        };
                    }
                },
                {
                    id: 'but-create-continue',
                    text: 'Create and Continue',
                    click: function() {}
                }
            ]
        });
    }

    function createMetric() {
        console.debug(blocklyHandler.getFormula());
        return false;
    }

    function closeDialog(this_) {
        $(this_).dialog('close');
        $(this_).remove();
    }

    loadMetricCategoryData();

    // var dialogModal = $("<div>", {id: "dialog-modal", title: "Create new metric"});
    
    // var dialogForm = $('<form>', {method: 'POST'}).appendTo(dialogModal);


  

    // $('<div>', {id: 'type-metric'})
    //     .css('border', '1px solid #cccccc')
    //     .css('padding', '10px')
    //     .css('float', 'left')
    //     .css('margin-right', '20px')
    //     .append('<input type="radio" name="type-metric-radio" value="0" checked="checked">Node<br>')
    //     // .append('<input type="radio" name="type-metric-radio" value="1">Service metric<br>')
    //     .append('<input type="radio" name="type-metric-radio" value="2">Service<br>')
    //     .appendTo(dialogForm);

    // var myContainer = $('<div>', {id: 'node-metric-container'})
    // myContainer
    //     .css('height', '100px');


    // var myLabel = $('<label>', {text: 'Name :'});
    // myLabel
    //     .css('display', 'inline-block')
    //     .css('width', '100px')
    //     .css('text-align', 'right');
    // var myInput = $('<input>', {type: 'text'});
    // myInput
    //     .css('margin-left', '10px')
    
    // var myContent = $('<p>')
    //                     .append(myLabel)
    //                     .append(myInput);

    // myContainer.append(myContent);

    // var myLabel = $('<label>', {text: 'Formula :'});
    // myLabel
    //     .css('display', 'inline-block')
    //     .css('width', '100px')
    //     .css('text-align', 'right');
    // var myInput = $('<input>', {type: 'text'});
    // myInput
    //     .css('margin-left', '10px')

    // var myContent = $('<p>')
    //                     .append(myLabel)
    //                     .append(myInput);

    // myContainer.append(myContent);

    // myContainer.appendTo(dialogForm);





    // Début Graphes


    // var myContainer = $('<div>', {id: 'service-metric-container'})
    //                     .css('display', "none");
    // myContainer
    //     .css('height', '100px');

    // var myContent = $('<p>', {text: 'SERVICE METRIC FORM'});

    // myContainer.append(myContent);

    // myContainer.appendTo(dialogForm);

    // var myContainer = $('<div>', {id: 'service-combination-container'})
    //                     .css('display', "none");
    // myContainer
    //     .css('height', '100px');


    // var myContent = $('<p>', {text: 'SERVICE COMBINATION FORM'});

    // myContainer.append(myContent);

    // myContainer.appendTo(dialogForm);

    // var myContent = $('<div>');
    // myContent
    //     .css('clear', 'both')
    //     .css('margin-top', '20px')
    //     .css('background-color', '#dddddd')
    //     .css('height', '1px');

    // dialogModal.append(myContent);

    // $(document).on("change", '#dialog-modal input:radio[name="type-metric-radio"]', function(event, ui) {
    //     var myValue = parseInt($('#dialog-modal input:radio[name="type-metric-radio"]:checked').val(), 10);
    //     switch (myValue) {
    //         case 0:
    //             $('#service-metric-container').css('display', 'none');
    //             $('#service-combination-container').css('display', 'none');
    //             $('#node-metric-container').css('display', 'block');
    //             break;

    //         case 1:
    //             $('#node-metric-container').css('display', 'none');
    //             $('#service-combination-container').css('display', 'none');
    //             $('#service-metric-container').css('display', 'block');
    //             break;

    //         case 2:
    //             $('#node-metric-container').css('display', 'none');
    //             $('#service-metric-container').css('display', 'none');
    //             $('#service-combination-container').css('display', 'block');
    //             break;
    //     }
    // });

    // // Nodemetric bargraph details handler
    // function nodeMetricDetailsBargraph2(cid, nodeMetric_id) {
    //   integrateWidget(cid, 'widget_nodes_bargraph', function(widget_div) {
    //       widget_div.find('.indicator_dropdown').remove();
    //       widget_div.find('.nodes_order_selection').hide();
    //       showNodemetricCombinationBarGraph(widget_div, nodeMetric_id, '', elem_id);
    //   });
    // }

    // Fin Graphes



    // var cid = 'content_nodesgraph2';
    // var nodeMetric_id = 366;



    // dialogModal.append($('<div>', {id: cid}));

    // nodeMetricDetailsBargraph2(cid, nodeMetric_id);

    // console.log('integrateWidget:' + cid);




    // var cont = $('<div>', {id: cid});

    // dialogModal.append(cont);

    // $('body').append.dialogModal;


    // var myInterval = setInterval(function() {myTimer()}, 200);
    // function myTimer() {
    //     // console.log(window.location.pathname);
    //     if ($('#' + cid).length > 0) {
    //         clearInterval(myInterval);
    //         nodeMetricDetailsBargraph2(cid, nodeMetric_id);
    //     }
    // }



    // var widget_div = $('<div>', { 'class' : 'widgetcontent' });
    // $(cont).addClass('widget').append(widget_div);
    // widget_div.load('/widgets/widget_nodes_bargraph.html', function() {
    //       widget_div.find('.indicator_dropdown').remove();
    //       widget_div.find('.nodes_order_selection').hide()  ;
    //       showNodemetricCombinationBarGraph(widget_div, nodeMetric_id, '', elem_id);
    //   });







    // alert(dialogForm.text());

    // $(button).click(function() {
    //     dialogModal.dialog({
    //         resizable: false,
    //         modal: true,
    //         dialogClass : "no-close",
    //         width: 700,
    //         buttons : [
    //             {id: 'but-cancel', text:'Cancel', click: function() {$(this).dialog('close');}},
    //             {id:'but-create',text:'Create',click: function() {$(this).dialog('close');}},
    //             {id:'but-create-continue',text:'Create and Continue',click: function() {}}
    //         ]
    //     });
    // });
};

function loadServicesMonitoring2(container_id, elem_id, ext, mode_policy) {

    var container = $("#" + container_id);
    var external = ext || '';

    // Nodemetric bargraph details handler
    function nodeMetricDetailsBargraph(cid, nodeMetric_id) {
      integrateWidget(cid, 'widget_nodes_bargraph', function(widget_div) {
          widget_div.find('.indicator_dropdown').remove();
          widget_div.find('.nodes_order_selection').hide()  ;
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

    /**
     * Metric list
     */

    var content = $('<div>', {id : 'metric-list-content'});
    var buttonsContainer = $('<div>', {id: 'metric-list-buttons-container', class: 'action_buttons'});
    var gridContainer = $('<div>', {id: 'metric-list-grid-container'});
    var gridId = 'metric-list-grid' + elem_id;

    function addButtons() {

        // Create button
        var button = $("<button>", {html: 'Add a metric'});
        button.button({icons: {primary: 'ui-icon-plusthick'}});

        $(button).click(function() {
            openCreateDialog();
        });

        buttonsContainer.append(button);

        // Delete button is created by displayList function below

        // Import button
        if (!mode_policy) {
            importItemButton(
                buttonsContainer,
                elem_id,
                {
                    name        : 'combination',
                    label_attr  : 'nodemetric_combination_label',
                    desc_attr   : 'formula_label',
                    type        : 'nodemetric_combination'
                },
                [gridId]
                );
        }
    }

    function createHtmlStructure() {
        content
            .append(buttonsContainer)
            .append(gridContainer)
            .appendTo(container);
    }

    function addLevelToCombination(list) {
        var level;
        for (var i = 0; i < list.length; i++) {
            list[i].level = 'node';
            if (list[i].hasOwnProperty('aggregate_combination_id')) {
                list[i].level = 'service';
            };
        };
    }

    function getValueFromList(rowId, columnName) {
        return $('#' + gridId).jqGrid('getCell', rowId, columnName);
    }

    function getDeleteActionUrl() {
        return function(rowId) {
            var url;
            var level = getValueFromList(rowId, 'level');
            switch(level) {
                case 'node':
                    url = '/api/nodemetriccombination';
                    break;
                case 'service':
                    url = '/api/aggregatecombination';
                    break;
            }
            return url;
        };
    }

    function getDetailsTabs() {
        return function(rowId) {
            var level = getValueFromList(rowId, 'level');
            var tabs;
            switch(level) {
                case 'node':
                    tabs = [
                        {label: 'Nodes graph', id: 'nodesgraph', onLoad: nodeMetricDetailsBargraph},
                        {label: 'Histogram', id: 'histogram', onLoad: nodeMetricDetailsHistogram},
                        {label: 'Historical', id: 'historical', onLoad: nodeMetricDetailsHistorical}
                    ];
                    break;
                case 'service':
                    tabs = [
                        {label: 'Historical graph', id: 'servicehistoricalgraph', onLoad: clusterMetricCombinationDetailsHistorical}
                    ];
                    break;
            }
            return tabs;
        };
    }

    function displayList() {

        create_grid({
            caption: '',
            url: '/api/combination?combination_formula_string=LIKE,%[a-zA-Z]%&service_provider_id=' + elem_id,
            loadComplete: function(data) {
                addLevelToCombination(data.rows);
            },
            content_container_id: gridContainer.attr('id'),
            grid_id: gridId,
            colNames: ['id', 'Name', 'Formula', 'Level'],
            colModel: [
                {name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
                {name: 'label', index: 'label', width: 90},
                {name: 'formula_label', index: 'formula_label', width: 200},
                {name: 'level', index: 'level', hidden: true}
            ],
            rowNum: 100,
            details: {
                tabs: getDetailsTabs(),
                title: {from_column: 'label'},
                height: 600,
                buttons: ['button-ok']
            },
            deactivate_details: mode_policy,
            action_delete: {
                callback: function (id) {
                    var url = getDeleteActionUrl().call(null, id) + '/';
                    confirmDeleteWithDependencies(url, id, [gridId]);
                }
            },
            multiselect: !mode_policy,
            multiactions: {
                multiDelete: {
                    label: 'Delete metric(s)',
                    action: removeGridEntry,
                    url: getDeleteActionUrl(),
                    icon: 'ui-icon-trash',
                    extraParams: {multiselect: true}
                }
            }
        });
    }

    addButtons();
    createHtmlStructure();
    displayList();

    // Service
    // $('<h3><a href="#">Service</a></h3>').appendTo(content);

    // var clustermetric_grid_id = 'service_resources_clustermetrics_' + elem_id;
    // var aggregatecombi_grid_id = 'service_resources_aggregate_combinations_' + elem_id;
    // var service_monitoring_accordion_container = $('<div>', {id : 'service_monitoring_accordion_container'});
    // content.append(
    //     service_monitoring_accordion_container.append(
    //         $('<div>')
    //             .append( $('<div>', {id : 'service_metrics_action_buttons', class : 'action_buttons'}) )
    //             .append( $('<div>', {id : 'service_metrics_container'}) )
    //     )
    // );

    // createServiceMetric('service_metrics_action_buttons', elem_id, (external !== '') ? true : false);
    // create_grid( {
    //     caption : 'Metrics',
    //     url: '/api/serviceprovider/' + elem_id + '/clustermetrics',
    //     content_container_id: 'service_metrics_container',
    //     grid_id: clustermetric_grid_id,
    //     colNames: [ 'id', 'Name', 'Function', 'Indicator' ],
    //     colModel: [
    //         { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
    //         { name: 'clustermetric_label', index: 'clustermetric_label', width: 90 },
    //         { name: 'clustermetric_statistics_function_name', index: 'clustermetric_statistics_function_name', width: 90 },
    //         { name: 'indicator_label', index: 'indicator_label', width: 200 }
    //     ],
    //     action_delete: {
    //         callback : function (id) {
    //             confirmDeleteWithDependencies('/api/clustermetric/', id, [clustermetric_grid_id, aggregatecombi_grid_id]);
    //         }
    //     },
    //     deactivate_details  : mode_policy,
    //     multiselect : !mode_policy,
    //     multiactions : {
    //         multiDelete : {
    //             label       : 'Delete service metric(s)',
    //             action      : removeGridEntry,
    //             url         : '/api/clustermetric',
    //             icon        : 'ui-icon-trash',
    //             extraParams : {multiselect : true}
    //         }
    //     }
    // } );

    // Service Metric Combinations
    // $("<p>").appendTo('#service_monitoring_accordion_container');

    // service_monitoring_accordion_container.append(
    //     $('<div>')
    //         .append( $('<div>', {id : 'service_metric_comb_action_buttons', class : 'action_buttons'}) )
    //         .append( $('<div>', {id : 'service_metric_comb_container'}) )
    // );

    // createServiceCombination('service_metric_comb_action_buttons', elem_id);
    // if (!mode_policy) {
    //     importItemButton(
    //             service_monitoring_accordion_container.find('#service_metric_comb_action_buttons'),
    //             elem_id,
    //             {
    //                 name        : 'combination',
    //                 label_attr  : 'aggregate_combination_label',
    //                 desc_attr   : 'formula_label',
    //                 type        : 'aggregate_combination'
    //             },
    //             [clustermetric_grid_id, aggregatecombi_grid_id]
    //     );
    // }
    // create_grid( {
    //     caption: 'Metric combinations',
    //     url: '/api/aggregatecombination?service_provider_id=' + elem_id,
    //     content_container_id: 'service_metric_comb_container',
    //     grid_id: aggregatecombi_grid_id,
    //     colNames: [ 'id', 'Name', 'Formula', 'Unit' ],
    //     colModel: [
    //         { name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true },
    //         { name: 'aggregate_combination_label', index: 'aggregate_combination_label', width: 90 },
    //         { name: 'formula_label', index: 'formula_label', width: 200 },
    //         { name: 'combination_unit', index: 'combination_unit',  hidden: true }
    //     ],
    //     details: {
    //         tabs : [
    //                 { label : 'Historical graph', id : 'servicehistoricalgraph', onLoad : clusterMetricCombinationDetailsHistorical }
    //             ],
    //         title       : { from_column : 'aggregate_combination_label' },
    //         height      : 600,
    //         buttons     : ['button-ok']
    //     },
    //     deactivate_details  : mode_policy,
    //     action_delete: {
    //         callback : function (id) {
    //             confirmDeleteWithDependencies('/api/aggregatecombination/', id, [aggregatecombi_grid_id]);
    //         }
    //     },
    //     multiselect : !mode_policy,
    //     multiactions : {
    //         multiDelete : {
    //             label       : 'Delete service combination(s)',
    //             action      : removeGridEntry,
    //             url         : '/api/aggregatecombination',
    //             icon        : 'ui-icon-trash',
    //             extraParams : {multiselect : true}
    //         }
    //     }
    // } );

    // Accordion
    // $('#accordion_monitoring_rule').accordion({
    //     autoHeight  : false,
    //     active      : false,
    //     change      : function (event, ui) {
    //         // Set all grids size to fit accordion content
    //         ui.newContent.find('.ui-jqgrid-btable').jqGrid('setGridWidth', ui.newContent.width());
    //     }
    // });
};
