require('KIM/component.js');

var Kanopyaaggregator = (function(_super) {
    Kanopyaaggregator.prototype = new _super();

    function Kanopyaaggregator(id) {
        _super.call(this, id);

        this.displayed = [ 'time_step', 'storage_duration' ];
    };

    return Kanopyaaggregator;

})(Component);
