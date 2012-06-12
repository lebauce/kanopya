var DetailsTable = (function() {
    function DetailsTable(container_id, elem_id, opts) {
        this.container = $('#'+container_id);
        this.table = $('<table></table>');
        this.url = opts.url;
        this.fields = opts.fields;
        this.actions = [];
        
        this.buildTable();
    }
    
    DetailsTable.prototype.show = function () {
        var me = this;
        this.table.appendTo(this.container);
        this.actions.forEach(function(element, index, array) {
            element.appendTo(me.container);
        });
    }
    
    DetailsTable.prototype.hide = function () {
        this.table.detach();
        this.actions.forEach(function(element, index, array) {
            element.detach();
        });
    }
    
    DetailsTable.prototype.buildTable = function() {
        this.table.empty();
        $.ajax({
            type: 'GET', 
            async: false, 
            url: this.url, 
            contentType: 'application/json',
            dataType: 'json',
            success: $.proxy(function(data) { 
                var table = this.table; 
                for(key in this.fields) { 
                    if(data.hasOwnProperty(key)) {
                        var tr = $('<tr></tr>');
                        $('<td></td>', { style: 'font-weight: bold', text: this.fields[key].label+':' }).appendTo(tr);
                        $('<td></td>', { text: data[key] }).appendTo(tr);
                        tr.appendTo(table);
                    }
                }
            }, this) 
        });
    }
    
    DetailsTable.prototype.addAction = function(opts) {
        var button = $('<button>', { text: opts.label });            
        button.bind('click', function() {
                opts.action();
        });
        this.actions.push(button);
    }
    
    DetailsTable.prototype.refresh = function() {
        this.buildTable();
        this.show();
    }
    
    return DetailsTable;
    
})();
