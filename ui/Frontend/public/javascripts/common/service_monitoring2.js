require('common/grid.js');
require('common/service_common.js');
require('common/service_item_import.js');

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

function openCreateDialog(serviceProviderId, gridId) {

    var dialogContainerId = 'metric-editor';
    var metricCatellgoryData, metricData, statisticFunctionData;
    var isResizing = false;
    var widgetContent = null;

    function loadMetricCategoryData() {
        $.getJSON("ajax/metric-category.json", function(data) {
            metricCategoryData = data;
            loadMetricData();
        });
    }

    function loadMetricData() {
        metricData = [];
        var indicators = getIndicators(serviceProviderId);
        for(indicator in indicators) {
            metricData.push({
                label: indicator,
                id: indicators[indicator].pk,
                categoryId: -1
            });
        }
        loadStatisticFunctionData();
    }

    function loadStatisticFunctionData() {
        $.getJSON("ajax/statistic-function.json", function(data) {
            statisticFunctionData = data;
            renderDialogTemplate();
        });
    }

    function renderDialogTemplate() {
        var templateFile = '/templates/metric-editor.tmpl.html';
        var options = {
            changeFormula: function() {
                formulaChanged();
            }
        };
        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('body').append(template(metricCategoryData));
            blocklyHandler.init(metricCategoryData, metricData, statisticFunctionData, options);
            setMetricPreview({'serviceMetric': null, 'nodeMetric': null});
            openDialog();
        });
    }

    function setMetricPreview(options) {

        var periodDate = {};
        var nodes = '';

        if (widgetContent !== null) {
            periodDate = getPickedDate(widgetContent);
            nodes = $.map(getSelectedNodes(widgetContent), function(val,i) {return val.id}).join(',');
        }
        if (nodes === '') {
            nodes = 'first';
        }

        $('#metric-preview').empty();
        integrateWidget('metric-preview', 'widget_historical_view', function(widget_div) {
            widgetContent = widget_div;
            // Select the first node by default
            widget_div.metadata = {
                node_ids: nodes
            };
            customInitHistoricalWidget(
                widget_div,
                serviceProviderId,
                {
                    'clustermetric_combinations': options.serviceMetric,
                    'nodemetric_combinations': options.nodeMetric,
                    'nodes': (options.nodeMetric !== null) ? 'from_ajax' : null
                },
                {
                    'open_config_part': false,
                    'allow_forecast': false,
                    'periodDate': periodDate,
                }
            );
        });
    }

    function openDialog() {
        $('#' + dialogContainerId).dialog({
            resizable: true,
            modal: true,
            dialogClass: "no-close",
            closeOnEscape: false,
            width: 1000,
            minwidth: 600,
            height: 600,
            buttons : [
                {
                    id: dialogContainerId + '-cancel-button',
                    text: 'Cancel',
                    click: function() {
                        closeDialog();
                    }
                },
                {
                    id: dialogContainerId + '-create-button',
                    text: 'Create',
                    disabled: true,
                    class: 'ui-state-disabled',
                    click: function() {
                        createMetric();
                    }
                }
            ],
            //custom handler for ESC key
            create: function() {
                $(this).closest('.ui-dialog').on('keydown', function(ev) {
                    if (ev.keyCode === $.ui.keyCode.ESCAPE) {
                        closeDialog();
                    }
                });
            },
            resize: function(event, ui) {
                blocklyContainerResize();
            },
            resizeStop: function(event, ui) {
                blocklyContainerResize();
            }
        });
        var containerLeft = $('#metric-items').position().left + $('#metric-items').outerWidth();
        $('#blockly-container').css('left', containerLeft + 'px');
        blocklyContainerResize();
        // Repeat blocklyContainerResize call : blockly width workaround
        setTimeout(function() {
            blocklyContainerResize();
        }, 100);
    }

    function blocklyContainerResize() {
        var containerWidth = $('#metric-formula').width() - $('#metric-items').width() - 10;
        $('.blocklySvg').attr('width', containerWidth);
    }

    function formulaChanged() {
        var formula = blocklyHandler.getFormula();
        var createButton = $('#' + dialogContainerId + '-create-button');
        var error = 0;
        var i, j, k, str;

        // Check if at least one metric is used in the formula
        if (formula.indexOf('[') === -1) {
            error = 1;
        }

        // Check if 0 value is used
        if (error === 0) {
            i = 0;
            j = formula.indexOf('0');
            var str;
            while (j > -1) {
                // 0 in first position or the previous character is not a number
                if (j === 0 || isNaN(parseInt(formula.charAt(j - 1), 10))) {
                    error = 2;
                    break;
                }
                j = formula.indexOf('0', j + 1);
            }
        }

        // Check if the formula combines service and node metric
        if (error === 0) {
            str = formula;
            // Remove service metric from the formula
            for (i = 0; i < statisticFunctionData.length; i++) {
                j = str.indexOf(statisticFunctionData[i].label);
                while (j > -1) {
                    k = str.indexOf(')', j);
                    str = str.substring(0, j) + str.substring(k + 1);
                    j = str.indexOf(statisticFunctionData[i].label);
                }
            }
            // Check if a node metric is used in the modified formula
            if (str !== formula && str.indexOf('[') > -1) {
                error = 3;
            }
        }

        if (error === 0) {
            $('#metric-formula').removeClass('error');
            createButton
                .removeAttr('disabled')
                .removeClass('ui-state-disabled');

            var options = {};
            var level = getFormulaLevel(formula);
            switch(level) {
                case 'node':
                    options.serviceMetric = null;
                    options.nodeMetric = [{'id': 367, 'name': '', 'unit': ''}];
                    break;
                case 'service':
                    formula = formatServiceIndicator(formula);
                    // options.serviceMetric = [{'formula': formula, 'name': '', 'unit': ''}];
                    options.serviceMetric = [{'id': 370, 'name': '', 'unit': ''}];
                    options.nodeMetric = null;
                    break;
            }
            setMetricPreview(options);
        } else {
            $('#metric-formula').addClass('error');
            createButton
                .attr('disabled', 'disabled')
                .addClass('ui-state-disabled');
        }
    }

    function createMetric() {
        var fields = {
            name: $('#metric-name').val(),
            // description: $('#metric-description').val(),
            formula: blocklyHandler.getFormula()
        }

        var level = getFormulaLevel(fields.formula);
        switch(level) {
            case 'node':
                createNodeMetric(fields);
                break;
            case 'service':
                createServiceMetric(fields);
                break;
        }
    }

    function getFormulaLevel(formula) {
        var level = 'node';
        for (var i = 0; i < statisticFunctionData.length; i++) {
            if (formula.indexOf(statisticFunctionData[i].label) > -1) {
                level = 'service';
                break;
            }
        }
        return level;
    }

    function createNodeMetric(fields) {
        var formula = formatNodeIndicator(fields.formula);

        $.ajax({
            url: '/api/nodemetriccombination',
            type: 'POST',
            data: {
                'nodemetric_combination_label': fields.name,
                'nodemetric_combination_formula': formula,
                // 'comment': fields.description,
                'service_provider_id': serviceProviderId,
            },
            success: function() {
                $('#' + gridId).trigger('reloadGrid');
            },
            complete: function() {
                closeDialog();
            }
        });
    }

    function formatNodeIndicator(formula) {
        formula = formula.replace(/\[/g, 'id');
        formula = formula.replace(/\]/g, '');
        return formula;
    }

    function createServiceMetric(fields) {
        var formula = formatServiceIndicator(fields.formula);

        $.ajax({
            url: '/api/aggregatecombination',
            type: 'POST',
            data: {
                'aggregate_combination_label': fields.name,
                'aggregate_combination_formula': formula,
                // 'comment': fields.description,
                'service_provider_id': serviceProviderId,
            },
            success: function() {
                $('#' + gridId).trigger('reloadGrid');
            },
            complete: function() {
                closeDialog();
            }
        });
    }

    function formatServiceIndicator(formula, isReadOnly) {
        var isReadOnly = isReadOnly || false;
        var statStartIndex, statEndIndex, metricStartIndex, metricEndIndex, nodeIndicatorId, serviceIndicatorId;
        // Allow to break the loop
        outerLoop:
        for (var i = 0; i < statisticFunctionData.length; i++) {
            statStartIndex = formula.indexOf(statisticFunctionData[i].label);
            while (statStartIndex > -1) {
                statEndIndex = formula.indexOf(')', statStartIndex);
                metricStartIndex = formula.indexOf('[', statStartIndex);
                metricEndIndex = formula.indexOf(']', statStartIndex);
                nodeIndicatorId = formula.substring(metricStartIndex + 1, metricEndIndex);
                serviceIndicatorId = getServiceIndicatorId(nodeIndicatorId, statisticFunctionData[i].code, serviceProviderId, isReadOnly);
                if (serviceIndicatorId === -1) {
                    formula = '';
                    break outerLoop;
                }
                formula = formula.substring(0, statStartIndex) + 'id' + serviceIndicatorId + formula.substring(statEndIndex + 1);
                statStartIndex = formula.indexOf(statisticFunctionData[i].label);
            }
        }
        if (formula) {
            formula = formatNodeIndicator(formula);
        }
        return formula;
    }

    function getServiceIndicatorId(nodeIndicatorId, statisticFunctionName, serviceProviderId, isReadOnly) {
        var serviceIndicatorId;
        $.ajax({
            url: '/api/clustermetric',
            data: {
                'clustermetric_statistics_function_name': statisticFunctionName,
                'clustermetric_indicator_id': nodeIndicatorId,
                'clustermetric_service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    serviceIndicatorId = data[0].pk;
                } else if (isReadOnly) {
                    serviceIndicatorId = -1;
                } else {
                    serviceIndicatorId = createServiceIndicator(nodeIndicatorId, statisticFunctionName, serviceProviderId);
                }
            }
        });
        return serviceIndicatorId;
    }

    function createServiceIndicator(nodeIndicatorId, statisticFunctionName, serviceProviderId) {
        var serviceIndicatorId;
        $.ajax({
            url: '/api/clustermetric',
            type: 'POST',
            data: {
                'clustermetric_statistics_function_name': statisticFunctionName,
                'clustermetric_indicator_id': nodeIndicatorId,
                'clustermetric_service_provider_id': serviceProviderId,
                'clustermetric_window_time': 1200
            },
            async: false,
            success: function(data) {
                serviceIndicatorId = data.pk;
            }
        });
        return serviceIndicatorId;
    }

    function closeDialog() {
        $('#' + dialogContainerId).dialog('close');
        $('#' + dialogContainerId).remove();
    }

    loadMetricCategoryData();
};

function loadServicesMonitoring2(container_id, elem_id, ext, mode_policy) {

    var container = $("#" + container_id);
    var external = ext || '';

    var content = $('<div>', {id : 'metric-list-content'});
    var buttonsContainer = $('<div>', {id: 'metric-list-buttons-container', class: 'action_buttons'});
    var gridContainer = $('<div>', {id: 'metric-list-grid-container'});
    var gridId = 'metric-list-grid' + elem_id;

    /**
     * Metric list
     */

    function addButtons() {

        // Create button
        var button = $("<button>", {html: 'Add a metric'});
        button.button({icons: {primary: 'ui-icon-plusthick'}});

        $(button).click(function() {
            openCreateDialog(elem_id, gridId);
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
};
