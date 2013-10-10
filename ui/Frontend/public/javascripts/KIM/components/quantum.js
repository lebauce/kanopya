require('KIM/component.js');

var Quantum = (function(_super) {
    Quantum.prototype = new _super();

    function Quantum(id) {
        _super.call(this, id);

        this.displayed = [ 'mysql5_id', 'nova_controller_id' ];
        this.relations = {};
    };

    return Quantum;

})(Component);
