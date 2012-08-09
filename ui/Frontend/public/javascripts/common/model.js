
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
        create_grid({
            content_container_id    : cid,
            grid_id                 : this.prototype.type + '_list',
            url                     : '/api/' + this.prototype.type,
            colNames                : this.prototype.columnNames    || [],
            colModel                : this.prototype.columnValues   || [],
            details                 : this.prototype.details        || { onSelectRow : $.noop }
        });
    };

    return Model;

})();
