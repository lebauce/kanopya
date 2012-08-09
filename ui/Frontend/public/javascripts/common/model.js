
var Model   = (function() {
 
    Model.prototype.type            = '';

    function Model(id, type) {
        this.id             = id;
        this.attrs          = {};
        this.type           = this.__proto__.type;

        if (this.id) {
            $.ajax({
                url     : '/api/' + this.type + '/' + this.id,
                success : (function(that) {
                    return (function(data) {
                        that.conf   = data;
                    });
                })(this)
            });
        }
    }

    Model.prototype.callRestFunction    = function(funcName, cb, data) {
        cb      = cb    || $.noop;
        data    = data  || {};
        $.ajax({
            url         : '/api/' + this.type + '/' + this.id + '/' + funcName,
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify(data),
            success     : (function(that) {
                return $.proxy(cb, that);
            })(this)
        });
    }

    Model.list  = function(cid) {
        /* Copy the columnNames and columnValues attributes avoiding create_grid from
         * populating them via references */
        var colNames    = (this.prototype.columnNames)  ? this.prototype.columnNames.slice(0)   : [];
        var colModel    = (this.prototype.columnValues) ? this.prototype.columnValues.slice(0)  : [];
        create_grid({
            content_container_id    : cid,
            grid_id                 : this.prototype.type + '_list',
            url                     : '/api/' + this.prototype.type,
            colNames                : colNames,
            colModel                : colModel,
            details                 : this.prototype.details || { onSelectRow : $.noop }
        });
    };

    return Model;

})();
