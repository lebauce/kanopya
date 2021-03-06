function setCellWithCallMethod(url, grid, rowid, colName, data) {
    $.ajax({
        type        : 'POST',
        contentType : 'application/json',
        data        : JSON.stringify(data || {}),
        url         : url,
        complete    : function(jqXHR, status) {
            if (status === 'success') {
                $(grid).setCell(rowid, colName, jqXHR.responseText);
            }
        }
    });
}

function setCellWithRelatedValue(url, grid, rowid, colName, fieldName, cb) {
    $.ajax({
        url     : url,
        success : function(data) {
            $(grid).setCell(rowid, colName, data[fieldName]);
            if (cb != null) {
                cb(grid, rowid);
            }
        }
    });
}

// Reload all visible grids
function reloadVisibleGrids() {
    $('.ui-jqgrid-btable:visible').trigger('reloadGrid');
}
