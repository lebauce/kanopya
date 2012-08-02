require('render.js');

var Component = (function() {
    function Component(id) {
        this.id     = id;
        this.conf   = {};
        if (id) {
            this.getConf();
        }
    }

    Component.prototype.getConf     = function() {
        $.ajax({
            url     : '/api/component/' + this.id + '/getConf',
            type    : 'POST',
            async   : false,
            success : function(that) {
                return (function(conf) {
                    that.conf   = conf;
                });
            }(this)
        });
    };

    Component.prototype.openConfig      = function() {
        var container   = $('<div>', {
            html : render('views/' + this.componentType, this.conf)
        });
    
        $(container).find('.button').each(function() {
            $(this).button({
                icons   : { primary : 'ui-icon-' + $(this).attr('rel') },
                text    : ($(this).text())
            });
        });

        $(container).dialog({
            draggable   : false,
            resizable   : false,
            modal       : true,
            close       : function() { $(this).remove(); },
            width       : 950,
            height      : 500,
            buttons     : {
                'Ok'        : function(component) {
                    return (function() {
                        if (component.validateConfig(container)) {
                            $(this).dialog('close');
                        }
                    });
                }(this),
                'Cancel'    : function() { $(this).dialog('close'); }
            }
        });
        return container;
    };

    Component.prototype.validateConfig  = function(container) {
        var form    = $(container).find('form');

        $(form).find(':input').each(function(that) {
            return (function() {
                that.conf[$(this).attr('name')] = $(this).val();
            });
        }(this));

        return this.save();
    };

    Component.prototype.save            = function() {
        var ret = false;
        $.ajax({
            async       : false,
            url         : '/api/component/' + this.id + '/setConf',
            type        : 'POST',
            contentType : 'application/json',
            data        : JSON.stringify({ conf : this.conf }),
            success     : function() { ret = true; }
        });
        return ret;
    };

    return Component;
})();
