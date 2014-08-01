require('common/grid.js');
require('common/service_common.js');

function loadServicesRules2(container_id, elem_id, ext, mode_policy) {

    var container = $("#" + container_id);
    var external = ext || '';
    var staticObject = {};

    var content = $('<div>', {id : 'list-content'});
    var buttonsContainer = $('<div>', {id: 'list-buttons-container', class: 'action_buttons'});
    var gridContainer = $('<div>', {id: 'list-grid-container'});
    var gridId = 'list-grid' + elem_id;

    function addButtons() {

        // Create button
        var button = $("<button>", {html: 'Add a rule'});
        button.button({icons: {primary: 'ui-icon-plusthick'}});

        $(button).click(function() {
            openRulesDialog(elem_id, gridId, staticObject, 'add');
        });

        buttonsContainer.append(button);

        // Delete button is created by displayList function below
    }

    function createHtmlStructure() {
        content
            .append(buttonsContainer)
            .append(gridContainer)
            .appendTo(container);
    }

    function getValueFromList(rowId, columnName) {
        return $('#' + gridId).jqGrid('getCell', rowId, columnName);
    }

    function anomalyDetailsHistorical(cid, anomaly_id, row_data) {
        var metric = {
            'id': row_data.related_metric_id
        };
        var formula = 'id' + metric.id;

        // Get service metric label
        $.ajax({
            url: '/api/clustermetric/' + metric.id,
            async: false,
            success: function(data) {
                metric.label = data.label;
            }
        });

        integrateWidget(cid, 'widget_historical_view', function(widget_div) {
            customInitHistoricalWidget(
                widget_div,
                elem_id,
                {
                    clustermetric_combinations: [
                        {'type': 'formula', 'formula': formula, 'name': metric.label, 'unit': ''},
                        {'type': 'anomaly', 'id': anomaly_id, 'name': row_data.label, 'unit': ''}
                    ],
                    nodemetric_combinations    : null,
                    nodes                      : 'from_ajax'
                },
                {
                    'open_config_part': false,
                    'allow_forecast': false
                }
            );
      });
    }

    function displayList() {

        create_grid({
            caption: '',
            url: '/api/rule?service_provider_id=' + elem_id,
            content_container_id: gridContainer.attr('id'),
            grid_id: gridId,
            colNames: ['id', 'Name', 'Enabled', 'Description'],
            colModel: [
                 {name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
                 {name: 'label', index: 'label', width: 90},
                 {name: 'state', index: 'state', width: 50,},
                 {name: 'description', index: 'description', width: 200}
            ],
            sortname: 'label',
            rowNum: 100,
            details: {
                tabs: [
                    {label: 'Historical graph', id: 'servicehistoricalgraph', onLoad: anomalyDetailsHistorical}
                ],
                title: {from_column: 'label'},
                height: 600,
                buttons: ['button-ok']
            },
            deactivate_details: mode_policy,
            action_delete: {
                callback: function (id) {
                    var url = '/api/anomaly/';
                    confirmDelete(url, id, [gridId]);
                }
            },
            multiselect: !mode_policy,
            multiactions: {
                multiDelete: {
                    label: 'Delete rule(s)',
                    action: removeGridEntry,
                    url: '/api/anomaly',
                    icon: 'ui-icon-trash',
                    extraParams: {multiselect: true}
                }
            }
        });
    }

    addButtons();
    createHtmlStructure();
    displayList();
}

function openRulesDialog(serviceProviderId, gridId, staticObject, action) {

    var dialogContainerId = 'rule-editor';
    var dialogTitle;
    var conditionHtml = {};
    var actionHtml = {};
    var statisticFunctionData;
    var indicatorData;
    var metricData;
    var function1PreviousValue;
    var function2PreviousValue;

    loadStatisticFunctionData();

    function loadStatisticFunctionData() {
        $('*').addClass('cursor-wait');
        // Delay to display the wait cursor
        setTimeout(function() {
            if (typeof staticObject.statisticFunctionData === 'undefined') {
                $.ajax({
                    dataType: 'json',
                    url: 'ajax/statistic-function.json',
                    async: false,
                    success: function(data) {
                        staticObject.statisticFunctionData = data;
                    }
                });
            }
            statisticFunctionData = staticObject.statisticFunctionData;
            loadIndicatorData();
        }, 10);
    }

    function loadIndicatorData() {
        if (typeof staticObject.indicatorData === 'undefined') {
            var data = [];
            var indicators = getIndicators(serviceProviderId);
            for(indicator in indicators) {
                data.push({
                    id: indicators[indicator].pk,
                    label: indicator
                });
            }
            staticObject.indicatorData = data;
        }
        indicatorData = staticObject.indicatorData;
        loadMetricData();
    }

    function getIndicators(serviceProviderId) {
        var indicators = {};
        $.ajax({
            url     : '/api/serviceprovider/' + serviceProviderId + '/service_provider_managers?expand=manager.collector_indicators.indicator&custom.category=CollectorManager',
            async   :false,
            success : function(data) {
                if (data.length > 0) {
                    $(data[0].manager.collector_indicators).each(function(i, collector_indicator) {
                        var indicator = collector_indicator.indicator;
                        indicators[indicator.indicator_label] = collector_indicator;
                    });
                }
            }
        });
        return indicators;
    }

    function loadMetricData() {
        if (typeof staticObject.metricData === 'undefined') {
            var metric = [];
            $.ajax({
                dataType: 'json',
                url: '/api/combination?combination_formula_string=LIKE,%[a-zA-Z]%&service_provider_id=' + serviceProviderId,
                async: false,
                success: function(data) {
                    $.each(data, function(index, obj) {
                        metric.push({
                            id: obj.pk,
                            label: obj.label,
                            level: (obj.hasOwnProperty('aggregate_combination_id')) ? 'service' : 'node'
                        });
                    });
                    staticObject.metricData = metric;
                }
            });
        }
        metricData = staticObject.metricData;
        renderDialogTemplate();
    }

    function renderDialogTemplate() {
        var templateFile = '/templates/rule-editor.tmpl.html';
        var dialogTitle = getDialogTitle();
        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('body').append(template({
                'title': dialogTitle,
                'statistic-function': statisticFunctionData,
                'indicator': indicatorData
            }));
            openDialog();
        });
    }

    function getDialogTitle() {
        var title;
        switch (action) {
            case 'add':
                title = 'Create a new rule';
                break;
            case 'edit':
                title = 'Edit';
                break;
        }
        return title;
    }

    function openDialog() {
        initConditionBuilder();
        initActionBuilder();
        $('*').removeClass('cursor-wait');
        $('#' + dialogContainerId).dialog({
            resizable: false,
            modal: true,
            dialogClass: "no-close",
            closeOnEscape: false,
            width: 1000,
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
                    id: dialogContainerId + '-save-button',
                    text: 'Save',
                    click: function() {
                        generateFormula();
                        // closeDialog();
                        // validateRule();
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
            }
        });

        addConditionGroup('#rule-conditions-builder', 0);

        $('#rule-actions-builder').find('.action-add').click(function() {
            addActionLine();
        });
    }

    function initConditionBuilder() {
        var element = $('#rule-conditions-builder').clone();
        conditionHtml.line = element.find(".condition").html();
        // Clean element classes
        element.find(".condition-group")
            .attr('class', 'condition-group');
        element.find(".condition")
            .empty()
            .attr('class', 'condition');
        conditionHtml.group = element.html();
    }

    function initActionBuilder() {
        var element = $('#rule-actions-builder').find('.action');
        actionHtml.line = element.html();
        // Clean element classes
        element
            .empty()
            .attr('class', 'action');
    }

    function validateRule() {
        $.getJSON(
            '/api/anomaly',
            {'related_metric_id': $('#metric').val()},
            function(data) {
                if (data.length > 0) {
                    $('#message').addClass('error');
                    $('#message').text('This service metric is already used.');
                } else {
                    createRule();
                }
            }
        );
    }

    function createRule() {
        var fields = {
            metric: $('#metric').val(),
        }
        $.ajax({
            url: '/api/anomaly',
            type: 'POST',
            data: {
                'related_metric_id': fields.metric
            },
            success: function() {
                $('#' + gridId).trigger('reloadGrid');
            },
            complete: function() {
                closeDialog();
            }
        });
    }

    function closeDialog() {
        $('#' + dialogContainerId).dialog('close');
        $('#' + dialogContainerId).remove();
    }

    function addConditionGroup(rootElement, level) {

        var tableElement, element;

        if (typeof rootElement === 'string') {
            rootElement = $(rootElement);
        }

        if (level > 0) {
            rootElement.append(conditionHtml.group);
        }
        tableElement = rootElement.find('table');

        element = tableElement.find('.condition');
        if (level === 0) {
            tableElement.find('.condition-remove-group').remove();
        } else {
            element.addClass('level-' + level + ' backcolor-' + (level % 4));

            tableElement.find('.condition-remove-group').click(function () {
                var element = $(this).closest('.condition-group');
                var parentElement = element.parent();
                element.remove();
                manageCondition(parentElement);

            });
        }
        addConditionLine(element, (level > 0));

        tableElement.find('.condition-add').click(function() {
            var element = tableElement.find('.condition').first();
            addConditionLine(element, true);
        });

        tableElement.find('.condition-add-group').click(function() {
            var element = tableElement.find('.condition').first();
            addConditionGroup(element, level + 1);
        });
    }

    function addConditionLine(rootElement, toAppend) {

        if (toAppend) {
            rootElement.append(conditionHtml.line);
        };

        var element = rootElement.children('.condition-line').last();
        element.children('.operand2').addClass('hidden');

        element.children('.function1')
            .focus(function() {
                function1PreviousValue = $(this).val();
            })
            .change(function() {
                if ($(this).val() === 'metric' || function1PreviousValue === 'metric') {
                    var element = $(this).siblings('.operand1');
                    element.children().remove();
                    var data = ($(this).val() === 'metric') ? metricData : indicatorData;
                    if ($(this).val() === 'metric') {
                        $.each(data, function(index, obj) {
                            element.append('<option value="' + obj.id + '" data-level="' + obj.level + '">' + obj.label + '</option>');
                        });
                    } else {
                        $.each(data, function(index, obj) {
                            element.append('<option value="' + obj.id + '">' + obj.label + '</option>');
                        });
                    }
                }
                function1PreviousValue = $(this).val();
            });

        element.children('.function2')
            .focus(function() {
                if ($(this).val() !== 'value' || function2PreviousValue === 'undefined') {
                    function2PreviousValue = $(this).val();
                }
            })
            .change(function() {
                var element = $(this).parent();
                if ($(this).val() === 'value') {
                    element.children('.operand2').addClass('hidden');
                    element.children('.condition-value').removeClass('hidden');
                } else {
                    element.children('.condition-value').addClass('hidden');
                    element.children('.operand2').removeClass('hidden');

                    if ($(this).val() === 'metric' || function2PreviousValue === 'metric') {
                        element = $(this).siblings('.operand2');
                        element.children().remove();
                        var data = ($(this).val() === 'metric') ? metricData : indicatorData;
                        if ($(this).val() === 'metric') {
                            $.each(data, function(index, obj) {
                                element.append('<option value="' + obj.id + '" data-level="' + obj.level + '">' + obj.label + '</option>');
                            });
                        } else {
                            $.each(data, function(index, obj) {
                                element.append('<option value="' + obj.id + '">' + obj.label + '</option>');
                            });
                        }
                    }
                }
                if ($(this).val() !== 'value') {
                    function2PreviousValue = $(this).val();
                }
        });

        element.children('.condition-remove').click(function() {
            var element = $(this).closest('.condition-line');
            var parentElement = element.parent();
            element.remove();
            manageCondition(parentElement);
        });

        manageCondition(rootElement);
    }

    function manageCondition(element) {
        var conditionElements = element.children();
        var selector = '.condition-remove';
        if ($(conditionElements[0]).hasClass('condition-group')) {
            selector = '.condition-remove-group';
        };
        var removeElement = element.find(selector).first();
        if (conditionElements.length === 1) {
            removeElement.addClass('hidden');
        } else {
            removeElement.removeClass('hidden');
        }
    }

    function addActionLine() {
        var element = $('#rule-actions-builder').find('.action');
        element.append(actionHtml.line);
        element.addClass('backcolor-0');

        element = element.children('.action-line').last();

        element.children('.action-name').change(function() {
            var element = $(this).parent();
            switch ($(this).val()) {
                case 'workflow':
                    element.children('.action-value').addClass('hidden');
                    element.children('.action-select').removeClass('hidden');
                    break;
                case 'email':
                    element.children('.action-select').addClass('hidden');
                    element.children('.action-value').removeClass('hidden');
                    break;
            }
        });

        element.children('.action-remove').click(function() {
            $(this).closest('.action-line').remove();

            var element = $('#rule-actions-builder').find('.action');
            if (element.find('.action-line').length === 0) {
                element.removeClass('backcolor-0');
            }
        });
    }

    function generateFormula() {
        var rootElement = $('#rule-conditions-builder').find('.condition-group.root').first();
        var formula = getFormula(rootElement);
        console.debug('formula', formula);
    }

    function getFormula(groupElement) {
        var element, str, value;
        var formula = '(';
        var operator = groupElement.find('.logic').first().val();
        var conditionElement = groupElement.find('.condition').first();
        var lineElements = conditionElement.children();
        $.each(lineElements, function(index, obj) {
            if (index > 0) {
                formula += ' ' + operator + ' ';
            }
            element = $(obj);
            if (element.hasClass('condition-group')) {
                formula += getFormula(element);
            } else {
                str = '[' + element.children('.operand1').val() + ']';
                value = element.children('.function1').val();
                if (value === 'metric') {
                    str = '|m' + str;
                } else {
                    str = '|i' + str;
                    if (value !== 'indicator') {
                        str = value + '(' + str + ')';
                    }
                }
                formula += str + ' ' + element.children('.operator').val();
                value = element.children('.function2').val();
                if (value === 'value') {
                    str = element.children('.condition-value').val();
                } else {
                    str = '[' + element.children('.operand2').val() + ']';
                    if (value === 'metric') {
                        str = '|m' + str;
                    } else {
                        str = '|i' + str;
                        if (value !== 'indicator') {
                            str = value + '(' + str + ')';
                        }
                    }
                }
                formula += ' ' + str;
            }
        });
        formula += ')';
        return formula;
    }
};
