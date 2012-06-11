var DetailsTable = (function() {
    function DetailsTable(container_id, elem_id, opts) {
        this.container = $('#'+container_id);
        this.table = $('<table>'); 
        
        for(key in opts.fields) { 
            var tr = $('<tr>');
            $('<td>', { style: 'font-weight: bold', text: key+':' }).appendTo(tr);
            $('<td>', { text: opts.fields[key].value }).appendTo(tr);
            tr.appendTo(this.table);
       }
       
       this.table.appendTo($('#'+container_id));
    
    }
    return DetailsTable;
    
})();
