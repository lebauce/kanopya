// jqgrid cell formatters

function fromIdToComponentType(cell, options, row) {
    
    var componentId = cell;
    var toReturn;
    
    $.ajax({
        async   : false,
        url     : '/api/componenttype?component_type_id=' + componentId,
        type    : 'GET',
        success : function(data) {
            toReturn = data[0].component_name;
        }
    });
    return toReturn;
}

// Set the correct state icon for each element :
function StateFormatter(cell, options, row) {
    if ( cell.indexOf('up') != -1 ) {
        return "<img src='/images/icons/up.png' title='up' />";
    } else if ( cell.indexOf('broken') != -1 ) {
        return "<img src='/images/icons/broken.png' title='broken' />";
    } else {
        return "<img src='/images/icons/down.png' title='down' />";
    }
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