// DetailsTable class

function DetailsTable(container_id, elem_id, opts) {
   
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
    
    DetailsTable.prototype._buildAttribute = function(label, value) {
        var tr = $('<tr></tr>');
        $('<td></td>', { style: 'font-weight: bold', text: label+':' }).appendTo(tr);
        $('<td></td>', { text: value }).appendTo(tr);
        tr.appendTo(this.table);
    }
    
    DetailsTable.prototype._buildTable = function() {
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
                        this._buildAttribute(this.fields[key].label, data[key]);
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
        this._buildTable();
        this.show();
    }
    
    this.container = $('#'+container_id);
    this.table = $('<table></table>');
    this.url = '/api/' + opts.name + '/' + elem_id;
    this.fields = opts.fields;
    this.actions = [];
    console.log(this);
    this._buildTable();
    
}

