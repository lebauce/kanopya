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

function openRulesDialog(serviceProviderId, gridId, staticObject, action, formula) {

    const dialogContainerId = 'rule-editor';

    var dialogTitle;
    var conditionHtml = {};
    var actionHtml = {};
    var statisticFunctionData;
    var indicatorData;
    var metricData;
    var function1PreviousValue;
    var function2PreviousValue;

    formula = formula || null;

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

        var element;

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
                        saveRule();
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

var formula = {
    'type': 'group',
    'logic': 'OR',
    'data': [
        {
            'type': 'line',
            'data': {
                'function1': 'indicator',
                'operand1': 330,
                'operator': '>',
                'function2': 'value',
                'operand2': 2
            }
        },
        {
            'type': 'group',
            'logic': 'OR',
            'data': [
                {
                    'type': 'line',
                    'data': {
                        'function1': 'metric',
                        'operand1': 382,
                        'operator': '>',
                        'function2': 'value',
                        'operand2': 4
                    }
                }
            ]
        },
        {
            'type': 'line',
            'data': {
                'function1': 'metric',
                'operand1': 432,
                'operator': '>',
                'function2': 'value',
                'operand2': 6
            }
        },
        {
            'type': 'group',
            'logic': 'AND',
            'data': [
                {
                    'type': 'line',
                    'data': {
                        'function1': 'min',
                        'operand1': 350,
                        'operator': '>',
                        'function2': 'metric',
                        'operand2': 432
                    }
                },
                {
                    'type': 'line',
                    'data': {
                        'function1': 'max',
                        'operand1': 355,
                        'operator': '>',
                        'function2': 'indicator',
                        'operand2': 350
                    }
                }
            ]
        }
    ]
};

        element = $('#rule-conditions-builder');
        addConditionGroup(element, 0);
        if (formula !== null) {
            element = element.children('.condition-group');
            buildConditionGroup(element, 0, formula)
        }

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

    function saveRule() {

        var formula = generateFormula();
        console.debug('formula', formula);

        if (checkRule(formula.string) === true) {
            var level = getFormulaLevel(formula.string);
            switch(level) {
                case 'node':
                    saveNodeRule();
                    break;
                case 'service':
                    saveServiceRule();
                    break;
            }
        }
    }

    function saveNodeRule() {

        console.debug('saveNodeRule');
            // formula.string = formatFormula(formula.string);
    }

    function saveServiceRule() {

        console.debug('saveServiceRule');
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

        var groupElement, element;

        if (level > 0) {
            rootElement.append(conditionHtml.group);
        }

        groupElement = rootElement.children('.condition-group').last();
        element = groupElement.find('.condition');

        if (level === 0) {
            groupElement.find('.condition-remove-group').remove();
        } else {
            element.addClass('level-' + level + ' backcolor-' + (level % 4));

            groupElement.find('.condition-remove-group').click(function () {
                var element = $(this).closest('.condition-group');
                var parentElement = element.parent();
                element.remove();
                manageCondition(parentElement);

            });
        }

        groupElement.find('.condition-add').click(function() {
            var element = groupElement.find('.condition').first();
            addConditionLine(element, true);
        });

        groupElement.find('.condition-add-group').click(function() {
            var element = groupElement.find('.condition').first();
            addConditionGroup(element, level + 1);
        });

        groupElement.find('td').first().children().focus(function() {
            $('#rule-conditions-builder').children('.error').remove();
            $('#rule-conditions-builder').find('select.field-error').removeClass('field-error');
        });

        addConditionLine(element, (level > 0));
        manageCondition(rootElement);
    }

    function addConditionLine(rootElement, toAppend) {

        if (toAppend) {
            rootElement.append(conditionHtml.line);
        };

        var element = rootElement.children('.condition-line').last();
        element.attr('id', getNewLineId());
        element.children('.operand2').addClass('hidden');

        element.children().focus(function() {
            $('#rule-conditions-builder').children('.error').remove();
            $('#rule-conditions-builder').find('select.field-error').removeClass('field-error');
        });

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

                if ($(this).val() === 'indicator' || $(this).val() === 'metric') {
                    $(this).removeClass('condition-content');
                } else {
                    $(this).addClass('condition-content');
                }
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

                if ($(this).val() === 'value' || $(this).val() === 'indicator' || $(this).val() === 'metric') {
                    $(this).removeClass('condition-content');
                } else {
                    $(this).addClass('condition-content');
                }
        });

        element.children('.condition-value').focus(function() {
                $(this).removeClass('field-error');
        });

        element.children('.condition-remove').click(function() {
            var element = $(this).closest('.condition-line');
            var parentElement = element.parent();
            element.remove();
            manageCondition(parentElement);
        });

        manageCondition(rootElement);
    }

    function getNewLineId() {
        var maxId = 0, curId;
        $('#rule-conditions-builder').find('.condition-line').each(function() {
            if ($(this).attr('id')) {
                curId = parseInt($(this).attr('id').substring('condition-line'.length), 10);
                if (curId > maxId) {
                    maxId = curId;
                }
            }
        });
        return 'condition-line' + (maxId + 1);
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

    function buildConditionGroup(rootElement, level, groupObject) {

        var element;

        rootElement.find('.logic').first().val(groupObject.logic);
        $.each(groupObject.data, function(index, obj) {
            switch (obj.type) {
                case 'line':
                    if (index > 0) {
                        rootElement.find('.condition-add').first().trigger('click');
                    }
                    element = rootElement.find('.condition').first().children('.condition-line').last();
                    element.children('.function1')
                        .val(obj.data.function1)
                        .trigger('change');
                    element.children('.operand1').val(obj.data.operand1);
                    element.children('.operator').val(obj.data.operator);
                    element.children('.function2')
                        .val(obj.data.function2)
                        .trigger('change');
                    if (element.children('.function2').val() === 'value') {
                        element.children('.condition-value').val(obj.data.operand2);
                    } else {
                        element.children('.operand2').val(obj.data.operand2);
                    }
                    break;

                case 'group':
                    if (index === 0) {
                        rootElement.find('.condition-line').first().remove();
                    }
                    rootElement.find('.condition-add-group').first().trigger('click');
                    element = rootElement.find('.condition').first().children('.condition-group').last();
                    buildConditionGroup(element, level + 1, obj);
                    break;
            }
        });
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
        var element = $('#rule-conditions-builder').find('.condition-group.root');
        return {
            string: getStringFormula(element),
            json: getJsonFormula(element)
        }
    }

    function getStringFormula(rootElement) {

        var element, str, value;

        var formula = '(';
        var operator = rootElement.find('.logic').first().val();
        var conditionElement = rootElement.find('.condition').first();
        var lineElements = conditionElement.children();

        $.each(lineElements, function(index, obj) {
            if (index > 0) {
                formula += ' ' + operator + ' ';
            }
            element = $(obj);
            if (element.hasClass('condition-group')) {
                formula += getStringFormula(element);
            } else {
                str = '[' + element.children('.operand1').val() + ']';
                value = element.children('.function1').val();
                if (value === 'metric') {
                    if (element.children('.operand1').find(':selected').data('level') === 'service') {
                        str = '|ms' + str;
                    } else {
                        str = '|mn' + str;
                    }
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
                        if (element.children('.operand2').find(':selected').data('level') === 'service') {
                            str = '|ms' + str;
                        } else {
                            str = '|mn' + str;
                        }
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

    function getJsonFormula(rootElement) {

        var element, lineObject;

        var formula = {
            'type': 'group',
            'logic': rootElement.find('.logic').first().val(),
            'data': []
        };

        var conditionElement = rootElement.find('.condition').first();
        var lineElements = conditionElement.children();

        $.each(lineElements, function(index, obj) {
            element = $(obj);
            if (element.hasClass('condition-group')) {
                formula.data.push(getJsonFormula(element));
            } else {
                lineObject = {
                    'type': 'line',
                    'id': element.attr('id'),
                    'data': {}
                }
                lineObject.data.function1 = element.children('.function1').val();
                lineObject.data.operand1 = element.children('.operand1').val();
                lineObject.data.operator = element.children('.operator').val();
                lineObject.data.function2 = element.children('.function2').val();
                if (lineObject.data.function2 === 'value') {
                    lineObject.data.operand2 = element.children('.condition-value').val();
                } else {
                    lineObject.data.operand2 = element.children('.operand2').val();
                }
                formula.data.push(lineObject);
            }
        });

        return formula;
    }

    function checkRule(stringFormula) {

        var message, str;
        var i, j, k;
        var ret = true;

        // Check the empty values
        $('#rule-conditions-builder').find('.condition-line').each(function() {
            if ($(this).children('.function2').val() === 'value' && $(this).children('.condition-value').val() === '') {
                ret = false;
                $(this).children('.condition-value').addClass('field-error');
            }
        });
        if (ret === false && $('#error1').length === 0) {
            message = 'The blank field(s) must be filled in.'
            $('#rule-conditions-builder').append('<p id="error1" class="error">' + message + '</p>');
        }

        // Check if the formula combines service and node metric
        str = stringFormula;
        console.debug(str);
        // Remove service indicator from the formula
        for (i = 0; i < statisticFunctionData.length; i++) {
            j = str.indexOf(statisticFunctionData[i].code);
            while (j > -1) {
                k = str.indexOf(')', j);
                str = str.substring(0, j) + str.substring(k + 1);
                j = str.indexOf(statisticFunctionData[i].code);
            }
        }
        // Remove service metric from the formula
        j = str.indexOf('|ms');
        while (j > -1) {
            k = str.indexOf(']', j);
            str = str.substring(0, j) + str.substring(k + 1);
            j = str.indexOf('|ms');
        }
        console.debug(str);
        // Check if a node metric is used in the modified formula
        if (str !== stringFormula && (str.indexOf('|i') > -1 || str.indexOf('|mn') > -1)) {
            ret = false;
            $('#rule-conditions-builder').find('.condition-line').each(function() {
                for (i = 1; i <= 2; i++) {
                    if ($(this).children('.function' + i).val() === 'indicator' || ($(this).children('.function' + i).val() === 'metric' && $(this).children('.operand' + i).find(':selected').data('level') === 'node')) {
                        $(this).children('.operand' + i).addClass('field-error');
                    }
                }
            });
            if ($('#error2').length === 0) {
                message = 'The condition(s) must be composed by either node or service combinations.'
                $('#rule-conditions-builder').append('<p id="error2" class="error">' + message + '</p>');
            }
        }

        return ret;
    }

    function getFormulaLevel(stringFormula) {

        var level = 'node';

        if (stringFormula.indexOf('|ms') > -1) {
            level = 'service';
        } else {
            for (var i = 0; i < statisticFunctionData.length; i++) {
                if (stringFormula.indexOf(statisticFunctionData[i].code) > -1) {
                    level = 'service';
                    break;
                }
            }
        }

        return level;
    }

    function formatFormula(stringFormula) {
        return stringFormula;
    }
};
