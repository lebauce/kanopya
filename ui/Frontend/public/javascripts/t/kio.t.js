
var steps = [
    {
        name            : 'Create tech service',
        start_condition : { exists : 'body' },
        action          : function() {
            menuGoTo('Administration', 'Technical Services');
            $('#create-tech-service-button').click();
            $('#input_externalcluster_name').val('Tech service test');
            $('.ui-dialog :button:contains("Ok"):visible').click();
        },
        end_condition   : { exists : '.ui-dialog-title:contains(Register IT application)' }
    },
    {
        name        : 'Select collector manager',
        action      : function() {
            $('option:contains(Collectormanager)').attr('selected', 'selected').parent('select').change();
        } ,
        end_condition   : { exists : 'option:contains(MockMonitor)' }
    },
    {
        name        : 'Select MockMonitor',
        action      : function() {
            $('option:contains(MockMonitor)').attr('selected', 'selected').parent('select').change();
        },
        end_condition   : { exists : 'form[action="/api/mockmonitor"]' }
    },
    {
        name        : 'add connector',
        action      : function() {
            $('.ui-button:contains("Ok"):visible').click();
        },
        end_condition   : { not_exists : '.ui-dialog' }
    },
    {
        name          : 'Create service',
        action      : function() {
            menuGoTo('Services');
            $('#add-service-button').click();
            $('#input_externalcluster_name').val('service_test');
            $('#input_externalcluster_desc').val('test service description');

            $('.ui-button:contains("Ok"):visible').click();
        },
        end_condition   : { exists : '.ui-dialog-title:contains(Link to a Collectormanager)' }
    },
    {
        name        : 'Add monitor manager',
        action      : function() {
            $('option:contains(Tech service test - MockMonitor)').attr('selected', 'selected').parent('select').change();
            $('.ui-button:contains("Ok"):visible').click();
        },
        end_condition   : {  not_exists : '.ui-dialog' }
    },
    {
        name        : 'Go to service details',
        action      : function() {
            menuGoTo('Services', 'service test', 'service_configuration');
        }
    }
];

var result_table = $('<table>').append($('<tr>').append($('<th>', {html : 'Step'})).append($('<th>', {html : 'Duration (ms)'})));
function record_step_result(name, duration) {
    result_table.append($('<tr>').append($('<td>', {html : name})).append($('<td>', {html : duration})));
}

var test_duration = 0;
var total_steps = 0;
function display_result() {
    $('<div>')
    .append(result_table)
    .append('<hr>')
    .append($('<span>', {
        html    : total_steps + ' steps in ' + (test_duration/1000) + ' seconds',
        style   : 'font-weight:bold'
    }))
    .dialog({
        title   : 'Test result',
        width   : 500,
        height  : 500
    });
}

function menuGoTo(entry, subentry, content_id) {
    if (entry) {
        $('#menuhead_' + entry.replace(' ', '_') + ' a').click();
    }
    if (subentry) {
        $('[id^="link_view_' + subentry.replace(' ', '_') + '_"] a').click();
    }
    if (content_id) {
        $('[href^="#content_' + content_id + '"]:visible').click();
    }
}

function launchStep(step_idx) {
    setTimeout( function() {
        var step_start_time = new Date().getTime();
        if (steps[step_idx]) {
            waitCond(
                    steps[step_idx].start_condition,
                    function() {
                        console.log('#### ' + steps[step_idx].name + ' ####');
                        steps[step_idx].action();
                        waitCond(steps[step_idx].end_condition, function() {
                            var step_duration = new Date().getTime() - step_start_time;
                            console.log('Done in ' + step_duration + ' ms');
                            test_duration += step_duration;
                            record_step_result(steps[step_idx].name, step_duration);
                            total_steps++;
                            launchStep(step_idx+1);
                        });
                    }
            );
        } else {
            console.log('## End test ###');
            display_result();
        }
    }, 1000); // We wait between each step to be sure all elements are correctly loaded
}

function waitCond(condition, onMet) {
    if (condition) {
        function _waitCond() {
            if ((condition.exists != undefined && $(condition.exists).length > 0) ||
                (condition.not_exists != undefined && $(condition.not_exists).length == 0)) {
                onMet();
            } else {
                setTimeout(_waitCond, 10);
            }
        }
        _waitCond();
    } else {
        onMet();
    }
}

console.log('Test begin');
launchStep(0);

