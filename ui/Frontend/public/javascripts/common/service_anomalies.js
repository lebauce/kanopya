require('common/grid.js');
require('common/service_common.js');

function loadServicesAnomalies(container_id, elem_id, ext, mode_policy) {

    var container = $("#" + container_id);
    var external = ext || '';

    var content = $('<div>', {id : 'list-content'});
    var buttonsContainer = $('<div>', {id: 'list-buttons-container', class: 'action_buttons'});
    var gridContainer = $('<div>', {id: 'list-grid-container'});
    var gridId = 'list-grid' + elem_id;

    function addButtons() {

        // Create button
        var button = $("<button>", {html: 'Add an anomalies detector'});
        button.button({icons: {primary: 'ui-icon-plusthick'}});

        $(button).click(function() {
            openCreateDialog(elem_id, gridId);
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

    function anomalyDetailsHistorical(cid, clusterMetric_id, row_data) {
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
            url: '/api/anomaly',
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
                    var url = '/api/anomaly';
                    confirmDeleteWithDependencies(url, id, [gridId]);
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

function openCreateDialog(serviceProviderId, gridId) {

    var dialogContainerId = 'anomaly-editor';
    var metricData;

    function loadMetricData() {
        metricData = [];
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
                renderDialogTemplate();
            }
        );
    }

    function renderDialogTemplate() {
        var templateFile = '/templates/anomaly-editor.tmpl.html';
        $.get(templateFile, function(templateHtml) {
            var template = Handlebars.compile(templateHtml);
            $('body').append(template({metric: metricData}));
            openDialog();
        });
    }

    function openDialog() {
        $('#' + dialogContainerId).dialog({
            resizable: false,
            modal: true,
            dialogClass: "no-close",
            closeOnEscape: false,
            width: 400,
            minwidth: 400,
            height: 230,
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

        $('#metric').change(function() {
            $('#message').removeClass();
            $('#message').text('');
        });
    }

    // Check if the new anomaly already exists
    function validateMetric() {
        $.getJSON(
            '/api/anomaly',
            {'related_metric_id': $('#metric').val()},
            function(data) {
                if (data.length > 0) {
                    $('#message').addClass('error');
                    $('#message').text('This service metric is already used.');
                } else {
                    createMetric();
                }
            }
        );
    }

    function createMetric() {
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

    loadMetricData();
};
