require('KIM/component.js');

var Kanopyacollector = (function(_super) {
    Kanopyacollector.prototype = new _super();

    function Kanopyacollector(id) {
        _super.call(this, id);

        this.displayed = [ 'time_step' ];
    };

    return Kanopyacollector;

})(Component);
