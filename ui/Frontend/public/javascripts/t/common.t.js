
/* ********************
 * Test utility functions
 **********************/

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

function clickOk() {
    $('.ui-button:contains("Ok"):visible').click();
}

function selectOption(option) {
    $('option:contains('+option+')').attr('selected', 'selected').parent('select').change();
}

/* **************************
 * Result display functions
 ****************************/

var result_table;
function record_step_result(name, duration) {
    result_table
    .append($('<tr>')
    .append($('<td>', {html : name}))
    .append($('<td>', {html : duration + 'ms', style : 'color:' + (duration > 10000 ? 'red' : (duration > 1000 ? 'orange' : 'green')) })));
}

var main_result_table = $('<table>').append($('<tr>').append($('<th>')));
function record_phase(name) {
    result_table = $('<table>').append($('<tr>').append($('<th>', {html : name, width : '300px'})).append($('<th>')));

    main_result_table
    .append($('<tr>')
    .append($('<td>').append(result_table)));

}

var test_duration = 0;
var total_steps = 0;
function display_result() {
    $('<div>')
    .append(main_result_table)
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

/* ***************************
 * Test management functions
 *****************************/

function launchStep(step_idx, steps) {
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
                            launchStep(step_idx+1, steps);
                        });
                    }
            );
        } else {
            console.log('## End Phase ###');
            nextPhase();
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

var phase_idx;
function nextPhase() {
    phase_idx++;
    var phase = _phases[phase_idx];
    if (phase) {
        record_phase(phase.name);
        launchStep(0, phase.steps);
    } else {
        display_result();
    }
}

var _phases;

function launchTest(phases) {
    _phases     = phases;
    phase_idx   = -1;
    console.log('Test begin');
    nextPhase();
}
