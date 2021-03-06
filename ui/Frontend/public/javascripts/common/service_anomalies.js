require('common/grid.js');
require('common/service_common.js');

function loadServicesAnomalies(container_id, elem_id, ext, mode_policy) {

    var container = $("#" + container_id);
    var external = ext || '';
    var metricObject = {};

    var content = $('<div>', {id : 'list-content'});
    var buttonsContainer = $('<div>', {id: 'list-buttons-container', class: 'action_buttons'});
    var gridContainer = $('<div>', {id: 'list-grid-container'});
    var gridId = 'list-grid' + elem_id;

    function addButtons() {

        // Create button
        var button = $("<button>", {html: 'Add an anomalies detector'});
        button.button({icons: {primary: 'ui-icon-plusthick'}});

        $(button).click(function() {
            openAnomalyCreateDialog(elem_id, gridId, metricObject);
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
            url: '/api/anomaly?related_metric.clustermetric.clustermetric_service_provider_id=' + elem_id,
            content_container_id: gridContainer.attr('id'),
            grid_id: gridId,
            colNames: ['id', 'Name', 'metricId'],
            colModel: [
                {name: 'pk', index: 'pk', width: 60, sorttype: 'int', hidden: true, key: true},
                {name: 'label', index: 'label', width: 90},
                {name: 'related_metric_id', index: 'related_metric_id', hidden: true}
            ],
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
                    label: 'Delete anomalies detector(s)',
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
};

function openAnomalyCreateDialog(serviceProviderId, gridId, metricObject) {

    var dialogContainerId = 'anomaly-editor';
    var metricData;

    if (typeof metricObject.data === 'undefined') {
        loadMetricData();
    } else {
        metricData = metricObject.data;
        renderDialogTemplate();
    }

    function loadMetricData() {
        metricData = [];
        $('*').addClass('cursor-wait');
        $.getJSON(
            '/api/clustermetric',
            {'clustermetric_service_provider_id': serviceProviderId},
            function(data) {
                $.each(data, function(index, obj) {
                    metricData.push({
                        label: obj.label,
                        id: obj.pk
                    });
                });
                metricObject.data = metricData;
                renderDialogTemplate();
            }
        );
    }

    function renderDialogTemplate() {
        var templateFile = '/templates/anomaly-editor.tmpl.html';
        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('body').append(template({
                metric: metricData,
                periodUnit: getPeriodUnitData()
            }));
            openDialog();
        });
    }

    function getPeriodUnitData() {
        return [
            {
                id: 'd',
                label: 'day(s)'
            },
            {
                id: 'w',
                label: 'week(s)'
            }
        ];
    }

    function openDialog() {
        $('*').removeClass('cursor-wait');
        $('#' + dialogContainerId).dialog({
            resizable: false,
            modal: true,
            dialogClass: "no-close",
            closeOnEscape: false,
            width: 600,
            // minwidth: 600,
            height: 400,
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
                    click: function() {
                        validateMetric();
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

        $('#anomaly-editor').find('input, select').change(function() {
            var element = $('#' + $(this).attr('id') + '-error');
            element.remove();
        });
    }

    function validateMetric() {

        var errorCount = 0;

        $.ajax({
            url: '/api/anomaly',
            type: 'GET',
            dataType: 'json',
            data: {
                'related_metric_id': $('#metric').val()
            },
            async: false,
            success: function(data) {
                if (data.length > 0) {
                    errorCount += 1;
                    displayError('metric', 'This service metric is already used.');
                }
            }
        });

        var fieldIdList = [
            'window',
            'period',
            'period-count'
        ];
        var re = /^\d+$/;
        var value;
        for (var i = 0; i < fieldIdList.length; i++) {
            value = $('#' + fieldIdList[i]).val();
            if (value !== '' && re.test(value) === false) {
                errorCount += 1;
                displayError(fieldIdList[i], 'This value must be an integer.');
            }
        }

        if (errorCount === 0) {
            createMetric();
        }
    }

    function displayError(fieldId, errorMessage) {
        var element = $('#' + fieldId + '-error');
        if (element.length === 0) {
            var html = '<div id="' + fieldId + '-error" class="error">' + errorMessage + '</div>';
            $('#' + fieldId).parent().append(html);
        }
    }

    function createMetric() {

        var value, list;
        var field = {
            'metric': $('#metric').val(),
        };

        value = $('#period').val();
        if (value) {
            switch ($('#period-unit').val()) {
                case 'd':
                    value *= 60 * 60 * 24;
                    break;
                case 'w':
                    value *= 60 * 60 * 24 * 7;
                    break;
            }
        }
        field.period = value;

        value = $('#window').val();
        if (value) {
            value = parseInt(value, 10);
        }
        field.window = value;

        value = $('#period-count').val();
        if (value) {
            value = parseInt(value, 10);
        }
        field.periodCount = value;

        $.ajax({
            url: '/api/anomaly',
            type: 'POST',
            data: {
                'related_metric_id': field.metric,
                'window': field.window,
                'period': field.period,
                'num_periods': field.periodCount
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
};
