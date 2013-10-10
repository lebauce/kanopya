// jqgrid cell formatters

function fromIdToComponentType(cell, options, row) {
    
    var componentId = cell;
    var componentType;
    
    $.ajax({
        async   : false,
        url     : '/api/componenttype?component_type_id=' + componentId,
        type    : 'GET',
        success : function(data) {
            componentType = data[0];
        }
    });
    return componentType;
}

function fromIdToComponentName(cell, options, row) {
    return fromIdToComponentType(cell, options,row).component_name;
}

function fromIdToComponentVersion(cell, options, row) {
    return fromIdToComponentType(cell, options,row).component_version;
}

// Set the correct state icon for each element :
function StateFormatter(cell, options, row) {
    // map state : icon
    var state_map = {
            'up'        : 'up',
            'in'        : 'up',
            'broken'    : 'broken',
            'down'      : 'down',
    };

    var curr_state = cell.split(':')[0];

    for (var state in state_map) {
        if (curr_state === state) {
            return "<img src='/images/icons/" + state_map[state] + ".png' title='" + curr_state + "' />";
        }
    }
    return "<img src='/images/icons/down.png' title='" + curr_state + "' />";
}

function booleanFormatter(cell, options, row) {
    return cell == 0 ? 'no' : 'yes';
}

function serviceStateFormatter(cell, options, row) {
    if (cell == 'enabled') {
        return "<img src='/images/icons/up.png' title='enabled' />";
    } else {
        return "<img src='/images/icons/down.png' title='disabled' />";
    }
}

function lastevalStateFormatter(cell, options, row) {
    if ( cell == 0 ) {
        return "<img src='/images/icons/up.png' title='up' />";
    } else if ( cell == 1 ) {
        return "<img src='/images/icons/broken.png' title='broken' />";
    } else if ( cell == null ) {
        return "<img src='/images/icons/down.png' title='down' />";
    }
}

function booleantostateformatter(val, yes, no) {
    if (val == 1) {
        return "<img src='/images/icons/up.png' title='" + (yes ? yes : 'up') + "' />";
    }
    else {
        return "<img src='/images/icons/down.png' title='" + (no ? no : 'down') + "' />";
    }
}

function datetimeformatter(timestamp) {
    var d   = new Date(parseInt(timestamp));
    return $.datepicker.formatDate('dd/mm/yy', d);
}

function timeformatter(timestamp) {
    var d   = new Date(parseInt(timestamp));
    return d.toLocaleTimeString().replace(/:00$/, '');
}

function bytesToMegsFormatter(size) {
    require('common/general.js');
    return (new String(convertUnits(size, 'B', 'M'))) + ' MB';
}
