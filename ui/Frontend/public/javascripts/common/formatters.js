// jqgrid cell formatters

// Set the correct state icon for each element :
function StateFormatter(cell, options, row) {
    //if (cell == 'up') {
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
    //if (cell == 'up') {
    if ( cell == 0 ) {
        return "<img src='/images/icons/up.png' title='up' />";
    } else if ( cell == 1 ) {
        return "<img src='/images/icons/broken.png' title='broken' />";
    } else if ( cell == null ) {
        return "<img src='/images/icons/down.png' title='down' />";
    }
}