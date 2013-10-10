require('KIM/component.js');

var Kanopyarulesengine = (function(_super) {
    Kanopyarulesengine.prototype = new _super();

    function Kanopyarulesengine(id) {
        _super.call(this, id);

        this.displayed = [ 'time_step' ];
    };

    return Kanopyarulesengine;

})(Component);
