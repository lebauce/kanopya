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