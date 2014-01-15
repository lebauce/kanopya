require('KIM/component.js');

var Neutron = (function(_super) {
    Neutron.prototype = new _super();

    function Neutron(id) {
        _super.call(this, id);

        this.displayed = [ 'mysql5_id', 'nova_controller_id' ];
        this.relations = {};
    };

    return Neutron;

})(Component);
