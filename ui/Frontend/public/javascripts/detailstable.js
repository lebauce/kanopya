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
                    var obj = data;
                    var fields = key.split('.');
                    for (var i = 0; obj && (i < fields.length - 1); i++) {
                        obj = obj[fields[i]];
                    }
                    if (!obj) {
                        continue;
                    }
                    var attr = fields[fields.length - 1];
                    if(obj.hasOwnProperty(attr)) {
                        this._buildAttribute(this.fields[key].label, obj[attr]);
                    }
                }
            }, this) 
        });
    }
    
    DetailsTable.prototype.addAction = function(opts) {
        var button = $('<button>', { text: opts.label }).button();            
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
    
    var query = '';
    $.each(opts.filters || {}, function (key, value) {
        query += (query == '' ? '?' : '&') + key + '=' + value;
    });

    this.url = '/api/' + opts.name + '/' + elem_id + query;
    this.fields = opts.fields;

    this.actions = [];
    this._buildTable();
    
}

