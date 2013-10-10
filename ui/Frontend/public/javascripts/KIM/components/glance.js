require('KIM/component.js');

var Glance = (function(_super) {
    Glance.prototype = new _super();

    function Glance(id) {
        _super.call(this, id);

        this.displayed = [ 'mysql5_id', 'nova_controller_id' ];
        this.relations = {};
    };

    return Glance;

})(Component);

