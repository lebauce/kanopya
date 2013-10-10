require('common/general.js');

function loadMonitorSettings(cid, eid) {
    loadAggregatorSettings(cid, eid);
    $('#' + cid).append('<hr>');
    loadOrchestratorSettings(cid, eid);
}

function loadOrchestratorSettings(cid, eid) {
    var container = $('#' + cid);

    // Retrieve current rulesengine component
    var rulesengine;
    $.ajax({
        url     : '/api/kanopyarulesengine',
        type    : 'GET',
        async   : false,
        success : function(data) {
            rulesengine = data[0];
        }
    });

    var time_step;
    $.ajax({
        url     : '/api/kanopyarulesengine/' + rulesengine.pk + '/getConf',
        type    : 'POST',
        async   : false,
        success : function(data) {
            time_step = data.time_step;
        }
    });

    // Frequency select
    var select_freq = $('<select>', {id : 'orch_freq'});
    for (var i=1; i<60; i++) {
        select_freq.append($('<option>', { value: i, html: i}))
    }

    // Set input to current values
    var freq_minutes = time_step / 60;
    select_freq.find('[value="' + freq_minutes + '"]').attr('selected', 'selected');

    // Display settings
    var table   = $("<table>").css("width", "100%").appendTo(container);
    $(table).append($("<tr>").append($("<td>", { colspan : 2, class : 'table-title', text : "Orchestrator settings" })));
    $(table).append($("<tr>").append($("<td>", { text : 'Frequency :', width : '200' })).append($("<td>").append(select_freq).append(' min')));
    $(table).append($("<tr>", { height : '15' }).append($("<td>", { colspan : 2 })));

    // Save settings button
    var update_button = $('<button>', {html : 'Apply'})
                        .button({ icons : { primary : 'ui-icon-wrench'} })
                        .click( function() {
                            var orch_freq    = $('#orch_freq :selected').val();
                            orch_freq        *= 60;

                            ajax('POST', '/api/kanopyarulesengine/' + rulesengine.pk + '/setConf', { conf : { time_step : orch_freq } });

                            // Update current conf
                            time_step           = orch_freq;
                            alert('ok');
                        });
    container.append(update_button);
}

function loadAggregatorSettings(cid, eid) {
    var container = $('#' + cid);

    // Retrieve current rulesengine component
    var aggregator;
    $.ajax({
        url     :'/api/kanopyaaggregator',
        type    : 'GET',
        async   : false,
        success : function(data) {
            aggregator = data[0];
        }
    });

    // Retrieve current aggregator conf
    var storage_duration;
    var time_step;
    $.ajax({
        url     : '/api/kanopyaaggregator/' + aggregator.pk + '/getConf',
        type    : 'POST',
        async   : false,
        success : function(data) {
            storage_duration    = data.storage_duration;
            time_step           = data.time_step;
        }
    });

    var week_seconds = 3600*24*7;
    var month_seconds = week_seconds*4;

    // Storage duration select
    var select_duration_amount = $('<select>', {id : 'store_duration_amount'});
    for (var i=1; i<=12; i++) {
        select_duration_amount.append($('<option>', { value: i, html: i}))
    }
    var select_duration_timescale = $('<select>', {id : 'store_duration_timescale'});
    var timescale_options = {'week(s)' : week_seconds, 'month(s)' : month_seconds};
    $.each(timescale_options, function(label, seconds) { select_duration_timescale.append($('<option>', { value: seconds, html: label}))});

    // Frequency select
    var select_freq = $('<select>', {id : 'agg_freq'});
    for (var i=1; i<60; i++) {
        select_freq.append($('<option>', { value: i, html: i}))
    }

    // Set input to current values
    var freq_minutes = time_step / 60;
    select_freq.find('[value="' + freq_minutes + '"]').attr('selected', 'selected');
    var duration_timescale;
    var duration_amount;

    if (storage_duration % month_seconds == 0) {
        duration_timescale  = month_seconds;
        duration_amount     = storage_duration / month_seconds;
    } else {
        duration_timescale  = week_seconds;
        duration_amount     = storage_duration / week_seconds;
    }
    select_duration_timescale.find('[value="' + duration_timescale + '"]').attr('selected', 'selected');
    select_duration_amount.find('[value="' + duration_amount + '"]').attr('selected', 'selected');

    // Display settings
    var table   = $("<table>").css("width", "100%").appendTo(container);
    $(table).append($("<tr>").append($("<td>", { colspan : 2, class : 'table-title', text : "Aggregator settings" })));
    $(table).append($("<tr>").append($("<td>", { text : 'Data storage duration :', width : '200' })).append($("<td>").append(select_duration_amount).append(select_duration_timescale)));
    $(table).append($("<tr>").append($("<td>", { text : 'Frequency :' })).append($("<td>").append(select_freq).append(' min')));
    $(table).append($("<tr>", { height : '15' }).append($("<td>", { colspan : 2 })));

    // Save settings button
    var update_button = $('<button>', {html : 'Apply'})
                        .button({ icons : { primary : 'ui-icon-wrench'} })
                        .click( function() {
                            var agg_freq            = $('#agg_freq :selected').val();
                            agg_freq                *= 60;
                            var duration_amount     = $('#store_duration_amount :selected').val();
                            var duration_timescale  = $('#store_duration_timescale :selected').val();
                            var store_duration = duration_amount * duration_timescale;

                            function updateConf() {
                                ajax('POST',
                                     '/api/kanopyaaggregator/' + aggregator.pk + '/setConf',
                                      { conf : { time_step         : agg_freq,
                                                 storage_duration  : store_duration } });

                                // Update current conf
                                storage_duration    = store_duration;
                                time_step           = agg_freq;
                            }

                            if (agg_freq != time_step) {
                                var warn_text = 'All aggregated data will be lost. Continue?';
                                $('<div>', {html : warn_text}).appendTo(container)
                                            .dialog({
                                                title   : 'Warning',
                                                dialogClass: "no-close",
                                                modal   : true,
                                                buttons : {
                                                    Yes: function () {
                                                        // Update conf
                                                        updateConf();

                                                        alert('ok');
                                                        $(this).dialog("close");
                                                    },
                                                    No: function () {
                                                        $(this).dialog("close");
                                                    }
                                                },
                                                close: function (event, ui) {
                                                    $(this).remove();
                                                }
                                            });
                            } else {
                                // Update conf
                                updateConf();
                                alert('ok');
                            }
                        });
    container.append(update_button);
}
