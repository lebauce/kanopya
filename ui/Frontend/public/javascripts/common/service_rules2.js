require('common/grid.js');
require('common/service_common.js');
require('common/notification_subscription.js');

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
            openRulesDialog(elem_id, gridId, staticObject);
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

    function getLevelById(id) {
        return (getValueFromList(id, 'aggregate_rule_id')) ? 'service' : 'node';
    }

    // This function allows to separate the old code
    function getDetails(wizard) {
        return function(rowId) {

            var options = {
                title: getValueFromList(rowId, 'label'),
                editDialogFunction: 'openRulesDialog',
                editDialogParameters: [elem_id, gridId, staticObject],
                onClose: function() {
                    $('#' + gridId).trigger('reloadGrid');
                }
            };

            var ret = {
                onOk: function () {
                    if (wizard !== null) {
                        wizard.validateForm();
                    }
                },
                title: {
                    from_column : 'label'
                }

            };
            switch(getLevelById(rowId)) {
                case 'node':
                    ret.tabs = [
                        {
                            label: 'Overview',
                            id: 'overview',
                            onLoad: function (cid, eid) {
                                wizard = ruleDetails(cid, eid, 'nodemetric_rule', options);
                            }
                        },
                        {
                            label: 'Nodes',
                            id: 'nodes',
                            onLoad: function(cid, eid) {
                                wizard = null;
                                rule_nodes_tab(cid, eid, elem_id);
                            },
                            hidden: mode_policy
                        }
                    ];
                    break;
                case 'service':
                    ret.tabs = [
                        {
                            label: 'Overview',
                            id: 'overview',
                            onLoad: function (cid, eid) {
                                wizard = ruleDetails(cid, eid, 'aggregate_rule', options);
                            }
                        }
                    ];
                    break;
            }

            return ret;
        };
    }

    function displayList() {

        var wizard;

        create_grid({
            caption: '',
            url: '/api/rule?service_provider_id=' + elem_id,
            content_container_id: gridContainer.attr('id'),
            grid_id: gridId,
            colNames: ['id', 'Name', 'Enabled', 'Description', 'aggregate_rule_id', 'Trigger', 'Alert'],
            colModel: [
                {name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
                {name: 'label', index: 'label', width: 90},
                {name: 'state', index: 'state', width: 50,},
                {name: 'description', index: 'description', width: 200},
                {name: 'aggregate_rule_id', index: 'aggregate_rule_id', hidden: true},
                { name: 'workflow_def_id', index: 'workflow_def_id', width: 120 },
                { name: 'alert', index: 'alert', width: 40, align: 'center', nodetails: true }
            ],
            sortname: 'label',
            rowNum: 100,
            // details: {
            //     onSelectRow: function(id) {
            //         openRulesDialog(elem_id, gridId, staticObject, id);
            //     }
            // },
            details: getDetails(wizard),
            deactivate_details: mode_policy,
            action_delete: {
                url : '/api/rule'
            },
            multiselect: !mode_policy,
            multiactions : {
                multiDelete : {
                    label       : 'Delete rule(s)',
                    action      : removeGridEntry,
                    url         : '/api/rule',
                    icon        : 'ui-icon-trash',
                    extraParams : { multiselect: true }
                }
            },
            afterInsertRow: function(grid, rowid, rowdata, rowelem) {
                if (rowdata.workflow_def_id) {
                    setCellWithRelatedValue('/api/workflowdef/' + rowdata.workflow_def_id, grid, rowid, 'workflow_def_id', 'workflow_def_name', filterNotifyWorkflow);
                }
                addSubscriptionButtonInGrid(grid, rowid, rowdata, rowelem, gridId + '_alert', 'ProcessRule', false);
            }
        });
    }

    // Added to use old functions
    var serviceRules = loadServicesRules(container_id, elem_id, ext, mode_policy, true);
    var ruleDetails = serviceRules.ruleDetails;

    addButtons();
    createHtmlStructure();
    displayList();
}

function openRulesDialog(serviceProviderId, gridId, staticObject, ruleId, onValidate) {

    const dialogContainerId = 'rule-editor';

    var dialogTitle;
    var conditionHtml = {};
    var actionHtml = {};
    var statisticFunctionData;
    var indicatorData;
    var metricData;
    var rule = {};
    var function1PreviousValue;
    var function2PreviousValue;

    ruleId = ruleId || 0;

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

        if (ruleId !== 0) {
            rule = getRule(ruleId);
        }

        var templateFile = '/templates/rule-editor.tmpl.html';
        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('body').append(template({
                'title': getDialogTitle(),
                'statistic-function': statisticFunctionData,
                'indicator': indicatorData
            }));
            openDialog();
        });
    }

    function getDialogTitle() {

        return (ruleId === 0) ? 'New rule' : rule.rule_name;
    }

    function getRule(ruleId) {

        var rule = {};

        $.ajax({
            dataType: 'json',
            url: '/api/rule',
            data: {
                'rule_id': ruleId
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    rule = data[0];
                }
            }
        });

        return rule;
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

        $('#rule-state').click(function() {
            var str = ($('#rule-state').prop('checked') === true) ? 'Enabled' : 'Disabled';
            $('#rule-state-caption')
                .toggleClass('enabled disabled')
                .text(str);
        });

        $('#rule-actions-builder').find('.action-add').click(function() {
            addActionLine();
        });

        addConditionGroup($('#rule-conditions-builder'), 0);
        if (ruleId !== 0) {
            initRule();
        }
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

    function initRule() {

        $('#rule-name').val(rule.rule_name);
        $('#rule-description').val(rule.description);
        if (rule.state === 'enabled') {
            $('#rule-state').prop('checked', true);
            $('#rule-state-caption')
                .removeClass('disabled')
                .addClass('enabled')
                .text('Enabled');
        } else {
            $('#rule-state').prop('checked', false);
            $('#rule-state-caption')
                .removeClass('enabled')
                .addClass('disabled')
                .text('Disabled');
        }

        if (rule.comment) {
            try {
                var jsonFormula = JSON.parse(rule.comment);
                var element = $('#rule-conditions-builder').children('.condition-group');
                buildConditionGroup(element, 0, jsonFormula);
            }
            catch (e) {
                var message = 'Unable to build this rule (JSON parsing error).'
                $('#rule-conditions-builder').append('<p class="error">' + message + '</p>');
            }
        } else {
            var level = 'node';
            if (rule.hasOwnProperty('aggregate_rule_id')) {
                level = 'service';
            }
            var jsonFormula = buildJsonFormula(rule.formula, level);
            if (jsonFormula === '#error') {
                var message = 'Missing JSON format: Unable to build automatically the rule.'
                $('#rule-conditions-builder').append('<p class="error">' + message + '</p>');
            } else {
                var element = $('#rule-conditions-builder').children('.condition-group');
                buildConditionGroup(element, 0, jsonFormula);
                var message = 'Missing JSON format: the rule has been builded automatically.'
                $('#rule-conditions-builder').append('<p class="info">' + message + '</p>');
            }
        }
    }

    function buildJsonFormula(formula, level, count) {

        count = count || 0;

        var text = removeBrackets(formula);
        var logic = 'AND';
        if (text.indexOf('||') > -1) {
            logic = 'OR';
        }
        if (text.indexOf('&&') > -1 && logic === 'OR') {
            return '#error';
        }
        var sourceLogic = (logic === 'AND') ? '&&' : '||';

        var jsonFormula = {
            'type': 'group',
            'logic': logic,
            'data': []
        };

        var lineList = [];
        var i, endIndex, str, line;

        text = formula;
        i = 0;
        while (i < text.length) {
            if (text.substr(i, 2) === 'id') {
                endIndex = text.indexOf(sourceLogic, i + 2);
                if (endIndex === -1) {
                    endIndex = text.length;
                }
                str = text.substring(i, endIndex);
                str = str.replace(/^\s+|\s+$/g, ''); // trim
                lineList.push(str);
                i = endIndex + 2;

            } else if (text.charAt(i) === '(') {
                str = extractBetweenBrackets(text.substr(i));
                if (str === '#error') {
                    return '#error';
                }
                lineList.push(str);
                i += str.length;
            } else if (text.substr(i, 2) === sourceLogic) {
                i += 2;
            } else if (text.charAt(i) === ' ') {
                i++;
            } else {
                return '#error';
            }
        }

        for (i = 0; i < lineList.length; i++) {
            count++;
            if (lineList[i].substr(0, 2) === 'id') {
                line = buildJsonLine(lineList[i], level, count);
            } else {
                line = buildJsonFormula(lineList[i], level, count);
            }
            if (line === '#error') {
                return '#error';
            }
            jsonFormula.data.push(line);
        }

        return jsonFormula;
    }

    function buildJsonLine(conditionId, level, count) {

        conditionId = conditionId.substr(2);
        var line = {
            'type': 'line',
            'id': 'condition-line' + count
        };
        var data;

        if (level === 'service') {
            data = buildServiceJsonLineData(conditionId);
        } else {
            data = buildNodeJsonLineData(conditionId);
        }
        if (data === '#error') {
            return '#error';
        }
        line.data = data;

        return line;
    }

    function buildServiceJsonLineData(conditionId) {

        var re, metricId, operandType;
        var lineData = {};
        var ret = true;

        $.ajax({
            url: '/api/aggregatecondition/' + conditionId,
            dataType: 'json',
            async: false,
            success: function(data) {
                lineData.id1 = data.left_combination_id;
                lineData.id2 = data.right_combination_id;
                lineData.operator = data.comparator;
            },
            error: function() {
                ret = false;
            }
        });
        if (ret === false) {
            return '#error';
        }

        for (var i = 1; i <= 2; i++) {
            if (i === 1) {
                operandType = 'metric';
            } else {
                $.ajax({
                    url: '/api/entity/' + lineData['id' + i],
                    dataType: 'json',
                    async: false,
                    success: function(data) {
                        if (data.hasOwnProperty('aggregate_combination_id')) {
                            operandType = 'metric';
                        } else if (data.hasOwnProperty('constant_combination_id')) {
                            operandType = 'constant';
                            lineData.id2 = data.constant_combination_id;
                            lineData.function2 = 'value';
                            lineData.operand2 = data.value;
                        } else {
                            ret = false;
                        }
                    },
                    error: function() {
                        ret = false;
                    }
                });
                if (ret === false) {
                    return '#error';
                }
            }

            if (operandType === 'metric') {
                $.ajax({
                    url: '/api/aggregatecombination/' + lineData['id' + i],
                    dataType: 'json',
                    async: false,
                    success: function(data) {
                        re = /^id\d+$/;
                        if (re.test(data.aggregate_combination_formula) === true) {
                            metricId = data.aggregate_combination_formula.substr(2);
                        } else {
                            metricId = null;
                            lineData['level' + i] = 'service';
                            lineData['function' + i] = 'metric';
                            lineData['operand' + i] = lineData['id' + i];
                        }
                    },
                    error: function() {
                        ret = false;
                    }
                });
                if (ret === false) {
                    return '#error';
                }

                if (metricId !== null) {
                    $.ajax({
                        url: '/api/clustermetric/' + metricId,
                        dataType: 'json',
                        async: false,
                        success: function(data) {
                            lineData['id' + i] = metricId;
                            lineData['level' + i] = 'service';
                            lineData['function' + i] = data.clustermetric_statistics_function_name;
                            lineData['operand' + i] = data.clustermetric_indicator_id;
                        },
                        error: function() {
                            ret = false;
                        }
                    });
                    if (ret === false) {
                        return '#error';
                    }
                }
            }
        }

        return lineData;
    }

    function buildNodeJsonLineData(conditionId) {

        var re, metricId, operandType;
        var lineData = {};
        var ret = true;

        $.ajax({
            url: '/api/nodemetriccondition/' + conditionId,
            dataType: 'json',
            async: false,
            success: function(data) {
                lineData.id1 = data.left_combination_id;
                lineData.id2 = data.right_combination_id;
                lineData.operator = data.nodemetric_condition_comparator;
            },
            error: function() {
                ret = false;
            }
        });
        if (ret === false) {
            return '#error';
        }

        for (var i = 1; i <= 2; i++) {
            if (i === 1) {
                operandType = 'metric';
            } else {
                $.ajax({
                    url: '/api/entity/' + lineData['id' + i],
                    dataType: 'json',
                    async: false,
                    success: function(data) {
                        if (data.hasOwnProperty('nodemetric_combination_id')) {
                            operandType = 'metric';
                        } else if (data.hasOwnProperty('constant_combination_id')) {
                            operandType = 'constant';
                            lineData.id2 = data.constant_combination_id;
                            lineData.function2 = 'value';
                            lineData.operand2 = data.value;
                        } else {
                            ret = false;
                        }
                    },
                    error: function() {
                        ret = false;
                    }
                });
                if (ret === false) {
                    return '#error';
                }
            }

            if (operandType === 'metric') {
                $.ajax({
                    url: '/api/nodemetriccombination/' + lineData['id' + i],
                    dataType: 'json',
                    async: false,
                    success: function(data) {
                        re = /^id\d+$/;
                        if (re.test(data.nodemetric_combination_formula) === true) {
                            metricId = data.nodemetric_combination_formula.substr(2);
                        } else {
                            metricId = null;
                            lineData['level' + i] = 'node';
                            lineData['function' + i] = 'metric';
                            lineData['operand' + i] = lineData['id' + i];
                        }
                    },
                    error: function() {
                        ret = false;
                    }
                });
                if (ret === false) {
                    return '#error';
                }

                if (metricId !== null) {
                    $.ajax({
                        url: '/api/collectorindicator/' + metricId,
                        dataType: 'json',
                        async: false,
                        success: function(data) {
                            lineData['level' + i] = 'node';
                            lineData['function' + i] = 'indicator';
                            lineData['operand' + i] = metricId;
                        },
                        error: function() {
                            ret = false;
                        }
                    });
                    if (ret === false) {
                        return '#error';
                    }
                }
            }
        }

        return lineData;
    }

    function removeBrackets(text) {

        var open = 0, closed = 0;
        var changed = true;
        var startIndex = 0;
        var openIndex, i;

        while (changed) {
            changed = false;
            for (i = startIndex; i < text.length; i++) {
                if (text.charAt(i) === '(') {
                    open++;
                    if (open === 1) {
                        openIndex = i;
                    }
                } else if (text.charAt(i) === ')') {
                    closed++;
                    if (open === closed) {
                        text = text.substring(0, openIndex) + text.substring(i + 1);
                        changed = true;
                        startIndex = openIndex + 1;
                        break;
                    }
                }
            }
        }

        return text;
    }

    function extractBetweenBrackets(text) {

        var open = 1, closed = 0;

        for (i = 1; i < text.length; i++) {
            if (text.charAt(i) === '(') {
                open++;
            } else if (text.charAt(i) === ')') {
                closed++;
                if (open === closed) {
                    text = text.substring(0, i + 1);
                    break;
                }
            }
        }
        if (i === text.length) {
            return '#error';
        }

        return text;
    }

    function saveRule() {

        $('*').addClass('cursor-wait');
        // Delay to display the wait cursor
        setTimeout(function() {
            var formula = generateFormula();

            if (checkRule(formula.string) === true) {
                var level = getFormulaLevel(formula.string);
                var rule = {
                    'id': ruleId,
                    'name': $('#rule-name').val(),
                    'description': $('#rule-description').val(),
                    'json': formula.json,
                    'formula': getRuleFormula(formula.json, level)
                };
                rule.state = ($('#rule-state').prop('checked') === true) ? 'enabled' : 'disabled';

                var ret = writeRule(rule, level);
                if (ret === true) {
                    $('#' + gridId).trigger('reloadGrid');
                    if (onValidate && typeof onValidate === 'function') {
                        onValidate.call(null);
                    }
                    closeDialog();
                } else if ($('#error3').length === 0) {
                    var message = 'Unable to save the rule.'
                    $('#rule-conditions-builder').append('<p id="error3" class="error">' + message + '</p>');
                }
            }
            $('*').removeClass('cursor-wait');
        }, 10);
    }

    function writeRule(rule, level) {

        var ret = false;
        var url = '/api/';
        var type = 'POST';
        switch (level) {
            case 'node':
                url += 'nodemetricrule';
                break;
            case 'service':
                url += 'aggregaterule';
                break;
        }
        if (rule.id > 0) {
            url += '/' + rule.id;
            type = 'PUT';
        }

        $.ajax({
            url: url,
            type: type,
            dataType: 'json',
            data: {
                'rule_name': rule.name,
                'description': rule.description,
                'formula': rule.formula,
                'comment': JSON.stringify(rule.json),
                'state': rule.state,
                'service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                ret = true;
            }
        });

        return ret;
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
            var element = $('#rule-conditions-builder');
            element.children('.error').remove();
            element.children('.info').remove();
            element.find('select.field-error').removeClass('field-error');
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
            var element = $('#rule-conditions-builder');
            element.children('.error').remove();
            element.children('.info').remove();
            element.find('select.field-error').removeClass('field-error');
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
                switch (lineObject.data.function1) {
                    case 'metric':
                        lineObject.data.level1 = element.children('.operand1').find(':selected').data('level');
                        break;
                    case 'indicator':
                        lineObject.data.level1 = 'node';
                        break;
                    default:
                        lineObject.data.level1 = 'service';
                        break;
                }
                if (lineObject.data.function1 === 'metric') {
                }
                lineObject.data.operator = element.children('.operator').val();
                lineObject.data.function2 = element.children('.function2').val();
                if (lineObject.data.function2 === 'value') {
                    lineObject.data.operand2 = element.children('.condition-value').val();
                } else {
                    lineObject.data.operand2 = element.children('.operand2').val();
                    switch (lineObject.data.function2) {
                        case 'metric':
                            lineObject.data.level2 = element.children('.operand2').find(':selected').data('level');
                            break;
                        case 'indicator':
                            lineObject.data.level2 = 'node';
                            break;
                        default:
                            lineObject.data.level2 = 'service';
                            break;
                    }
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

    function getRuleFormula(groupObject, level, isRoot) {

        var i, conditionId;
        var formula = '';
        var operator;
        switch (groupObject.logic) {
            case 'AND':
                operator = '&&'
                break;
            case 'OR':
                operator = '||'
                break;
        }

        isRoot = (isRoot === 'undefined') ? true : isRoot;

        $.each(groupObject.data, function(index, obj) {
            if (index > 0) {
                formula += ' ' + operator + ' ';
            }
            switch (obj.type) {
                case 'line':
                    for (i = 1; i <= 2; i++) {
                        switch (obj.data['function' + i]) {
                            case 'value':
                                obj.data['id' + i] = getConstantMetricId(obj.data['operand' + i], serviceProviderId);
                                break;
                            case 'indicator':
                                obj.data['id' + i] = getNodeMetricId(obj.data['operand' + i], serviceProviderId);
                                break;
                            case 'metric':
                                obj.data['id' + i] = obj.data['operand' + i];
                                break;
                            default:
                                obj.data['id' + i] = getServiceMetricId(obj.data['operand' + i], obj.data['function' + i], serviceProviderId);
                                break;
                        }
                    }
                    conditionId = getConditionId(obj.data, level, serviceProviderId);
                    formula += 'id' + conditionId;
                    break;

                case 'group':
                    formula += getRuleFormula(obj, level, false);
                    break;
            }
        });
        if (isRoot === false && groupObject.data.length > 1) {
            formula = '(' + formula + ')';
        }

        return formula;
    }

    function getConstantMetricId(constant, serviceProviderId) {

        var constantMetricId = -1;

        $.ajax({
            dataType: 'json',
            url: '/api/combination',
            data: {
                'combination_formula_string': constant,
                'service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    constantMetricId = data[0].pk;
                } else {
                    constantMetricId = 0;
                }
            }
        });

        return constantMetricId;
    }

    function getNodeMetricId(indicatorId, serviceProviderId) {

        var nodeMetricId = -1;

        $.ajax({
            dataType: 'json',
            url: '/api/nodemetriccombination',
            data: {
                'nodemetric_combination_formula': 'id' + indicatorId,
                'service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    nodeMetricId = data[0].pk;
                } else {
                    nodeMetricId = createNodeMetric(indicatorId, serviceProviderId);
                }
            }
        });

        return nodeMetricId;
    }

    function createNodeMetric(indicatorId, serviceProviderId) {

        var nodeMetricId = -1;

        $.ajax({
            url: '/api/nodemetriccombination',
            type: 'POST',
            data: {
                'nodemetric_combination_formula': 'id' + indicatorId,
                'service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                nodeMetricId = data.pk;
            }
        });

        return nodeMetricId;
    }

    function getServiceMetricId(indicatorId, statisticFunctionName, serviceProviderId) {

        var serviceMetricId = -1;

        var serviceIndicatorId = getServiceIndicatorId(indicatorId, statisticFunctionName, serviceProviderId);
        if (serviceIndicatorId === -1) {
            return -1;
        }

        $.ajax({
            dataType: 'json',
            url: '/api/aggregatecombination',
            data: {
                'aggregate_combination_formula': 'id' + serviceIndicatorId,
                'service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    serviceMetricId = data[0].pk;
                } else {
                    serviceMetricId = createServiceMetric(serviceIndicatorId, serviceProviderId);
                }
            }
        });

        return serviceMetricId;
    }

    function createServiceMetric(serviceIndicatorId, serviceProviderId) {

        var serviceMetricId = -1;

        $.ajax({
            url: '/api/aggregatecombination',
            type: 'POST',
            data: {
                'aggregate_combination_formula': 'id' + serviceIndicatorId,
                'service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                serviceMetricId = data.pk;
            }
        });

        return serviceMetricId;
    }

    function getServiceIndicatorId(indicatorId, statisticFunctionName, serviceProviderId, isReadOnly) {

        var serviceIndicatorId = -1;

        isReadOnly = isReadOnly || false;

        $.ajax({
            dataType: 'json',
            url: '/api/clustermetric',
            data: {
                'clustermetric_statistics_function_name': statisticFunctionName,
                'clustermetric_indicator_id': indicatorId,
                'clustermetric_service_provider_id': serviceProviderId
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    serviceIndicatorId = data[0].pk;
                } else if (isReadOnly) {
                    serviceIndicatorId = -1;
                } else {
                    serviceIndicatorId = createServiceIndicator(indicatorId, statisticFunctionName, serviceProviderId);
                }
            }
        });

        return serviceIndicatorId;
    }

    function createServiceIndicator(indicatorId, statisticFunctionName, serviceProviderId) {

        var serviceIndicatorId;

        $.ajax({
            url: '/api/clustermetric',
            type: 'POST',
            data: {
                'clustermetric_statistics_function_name': statisticFunctionName,
                'clustermetric_indicator_id': indicatorId,
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

    function getConditionId(obj, level, serviceProviderId) {

        var conditionId = -1;

        switch (level) {
            case 'node':
                conditionId = getNodeConditionId(obj, serviceProviderId);
                break;
            case 'service':
                conditionId = getServiceConditionId(obj, serviceProviderId);
                break;
        }

        return conditionId;
    }

    function getNodeConditionId(obj, serviceProviderId) {

        var nodeConditionId = -1;

        if (obj.id2 === 0) {
            nodeConditionId = createNodeCondition(obj, serviceProviderId);
        } else {
            $.ajax({
                dataType: 'json',
                url: '/api/nodemetriccondition',
                data: {
                    'left_combination_id': obj.id1,
                    'nodemetric_condition_comparator': obj.operator,
                    'right_combination_id': obj.id2,
                    'nodemetric_condition_service_provider_id': serviceProviderId
                },
                async: false,
                success: function(data) {
                    if (data.length > 0) {
                        nodeConditionId = data[0].pk;
                    } else {
                        nodeConditionId = createNodeCondition(obj, serviceProviderId);
                    }
                }
            });
        }

        return nodeConditionId;
    }

    function createNodeCondition(obj, serviceProviderId) {

        var nodeConditionId = -1;

        var data = {
            'left_combination_id': obj.id1,
            'nodemetric_condition_comparator': obj.operator,
            'nodemetric_condition_service_provider_id': serviceProviderId
        };
        if (obj.id2 === 0) {
            data.nodemetric_condition_threshold = obj.operand2;
        } else {
            data.right_combination_id = obj.id2;
        }

        $.ajax({
            url: '/api/nodemetriccondition',
            type: 'POST',
            data: data,
            async: false,
            success: function(data) {
                nodeConditionId = data.pk;
            }
        });

        return nodeConditionId;
    }

    function getServiceConditionId(obj, serviceProviderId) {

        var serviceConditionId = -1;

        if (obj.id2 === 0) {
            serviceConditionId = createServiceCondition(obj, serviceProviderId);
        } else {
            $.ajax({
                dataType: 'json',
                url: '/api/aggregatecondition',
                data: {
                    'left_combination_id': obj.id1,
                    'comparator': obj.operator,
                    'right_combination_id': obj.id2,
                    'aggregate_condition_service_provider_id': serviceProviderId
                },
                async: false,
                success: function(data) {
                    if (data.length > 0) {
                        serviceConditionId = data[0].pk;
                    } else {
                        serviceConditionId = createServiceCondition(obj, serviceProviderId);
                    }
                }
            });
        }

        return serviceConditionId;
    }

    function createServiceCondition(obj, serviceProviderId) {

        var serviceConditionId = -1;

        var data = {
            'left_combination_id': obj.id1,
            'comparator': obj.operator,
            'aggregate_condition_service_provider_id': serviceProviderId
        };
        if (obj.id2 === 0) {
            data.threshold = obj.operand2;
        } else {
            data.right_combination_id = obj.id2;
        }

        $.ajax({
            url: '/api/aggregatecondition',
            type: 'POST',
            data: data,
            async: false,
            success: function(data) {
                serviceConditionId = data.pk;
            }
        });

        return serviceConditionId;
    }
}
