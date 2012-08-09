require('KIM/component.js');

var Linux0      = (function(_super) {
    Linux0.prototype                    = new _super();

    function Linux0(id) {
        _super.call(this, id);
        this.componentType  = 'linux0';
    }

    Linux0.prototype.openConfig         = function() {
        var container       = Component.prototype.openConfig.call(this);
        var formTable       = $(container).find('table').find('tbody');
        var addRowButton    = $(container).find('a#addRow');

        addRowButton.bind('click', function(that) {
            return (function() {
                $(formTable).append(that.getRowDefinition());
            });
        }(this));
        $(container).find('a.delRowButton').each(function() {
            $(this).bind('click', function() {
                $(this).parents('tr').remove();
            });
        });
    };

    Linux0.prototype.validateConfig     = function(container) {
        var tableForm   = $(container).find('table').find('tbody');
        
        this.conf       = {
            linux_mountdefs : []
        };

        $(tableForm).find('tr').each(function(that) {
            return (function() {
                var entry   = {};
                $(this).find('input').each(function() {
                    entry[$(this).attr('name')]    = $(this).val();
                });
                that.conf.linux_mountdefs.push(entry);
            });
        }(this));

        return this.save();
    };

    Linux0.prototype.getRowDefinition   = function() {
        var closeButton = $('<a>').button({ icons : { primary : 'ui-icon-closethick' }, text : false });
        var line        = $('<tr>').append($('<td>').append($('<input>', { name : 'linux0_mount_device', size : '25' })))
                                   .append($('<td>').append($('<input>', { name : 'linux0_mount_point', size : '25' })))
                                   .append($('<td>').append($('<input>', { name : 'linux0_mount_filesystem', size : '6' })))
                                   .append($('<td>').append($('<input>', { name : 'linux0_mount_options' })))
                                   .append($('<td>').append($('<input>', { name : 'linux0_mount_dumpfreq', size : '2' })))
                                   .append($('<td>').append($('<input>', { name : 'linux0_mount_passnum', size : '2' })))
                                   .append($('<td>').append(closeButton));
        closeButton.bind('click', function() { $(line).remove(); });
        return line;
    };

    return Linux0;
})(Component);
