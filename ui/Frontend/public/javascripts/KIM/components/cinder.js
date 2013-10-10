require('KIM/component.js');

var Cinder = (function(_super) {
    Cinder.prototype = new _super();

    function Cinder(id) {
        _super.call(this, id);

        this.displayed = [ 'mysql5_id', 'nova_controller_id' ];
        this.relations = {};
    };

    return Cinder;

})(Component);
